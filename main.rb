require "watir"
require "rest-client"
require "json"
require "rspec"
require "cgi"
require "uri"
require "pry"
require "rubocop"
require "date"

# require relative the class file to be able to use classes and their functions
require_relative "class.rb"

# require relative to access the classes used for rspec tests
require_relative "rspec_class.rb"

# getting confidential info from a file
file = File.open(".bundle/confidential.txt")
file_data = File.read(".bundle/confidential.txt")
data_hash = JSON.parse(file_data)
file.close

# setting up query parameters
client_id = data_hash["client_id"]
response_type = "code"
redirect_uri = "https://example.com/callback"
client_secret = data_hash["client_secret"]
scope = "playlist-modify-public playlist-modify-private"

# requesting authorization
url = "https://accounts.spotify.com/authorize?client_id=#{client_id}&response_type=#{response_type}&redirect_uri=#{redirect_uri}&scope=#{scope}"

# starting Watir
browser = Watir::Browser.new
browser.goto url

# auto-login for not losing time
browser.text_field(id: "login-username").set("vadim.ojog@yahoo.com")
browser.text_field(id: "login-password").set("12345670000")
browser.button(id: "login-button").click

sleep 1 # browser to not close in

sleep 1

# get the authorization-code
res = CGI.parse(URI.parse(browser.url).query)
@authorization_code = res["code"]

# post request to get the access token, refresh token and the expiry time
token = RestClient::Request.execute(method: "post",
                                    url: "https://accounts.spotify.com/api/token",
                                    payload: {
                                      "grant_type" => "authorization_code",
                                      "code" => @authorization_code[0],
                                      "redirect_uri" => redirect_uri,
                                      "client_id" => client_id,
                                      "client_secret" => client_secret
                                    })

RSpec.describe "Successful request", type: :controller do
  describe "post index" do
    it "returns a 200" do
      response = token.code
      expect(response).to eq(200)
    end
  end
end

access_token = JSON.parse(token)["access_token"]
refresh_token = JSON.parse(token)["refresh_token"]
expires_in = JSON.parse(token)["expires_in"]

expires_at = DateTime.now + expires_in * 0.00000095 # equivalent of 5 mins added, time of expiration with the current Date and time standards
puts "expires_at = ", expires_at

# condition to send the refresh token and get a new access token
if expires_at < DateTime.now
  new_token = RestClient::Request.execute(method: "post",
                                          url: "https://accounts.spotify.com/api/token",
                                          payload: {
                                            "grant_type" => "refresh_token",
                                            "refresh_token" => refresh_token,
                                            "client_id" => client_id,
                                            "client_secret" => client_secret
                                          })

  RSpec.describe "Successful request", type: :controller do
    describe "post index" do
      it "returns a 200" do
        response = new_token.code
        expect(response).to eq(200)
      end
    end
  end

  access_token = JSON.parse(new_token)["access_token"]
  puts "new access token = ", access_token
end

# get request to get user_id
profile = RestClient::Request.execute(method: "get",
                                      url: "https://api.spotify.com/v1/me",
                                      headers: {
                                        "Authorization" => "Bearer #{access_token}"
                                      })

RSpec.describe "Successful request", type: :controller do
  describe "get index" do
    it "returns a 200" do
      response = profile.code
      expect(response).to eq(200)
    end
  end
end

user_id = JSON.parse(profile)["id"]

# post request to create a playlist and get its id
create_playlist = RestClient::Request.execute(method: "post",
                                              url: "https://api.spotify.com/v1/users/#{user_id}/playlists",
                                              payload: {
                                                "name" => "My new playlist",
                                                "description" => "new playlist description",
                                                "public" => false
                                              }.to_json,
                                              headers: {
                                                "Authorization" => "Bearer #{access_token}",
                                                "Content-Type" => "application/json",
                                                "Accept" => "application/json"
                                              })

RSpec.describe "Successful request", type: :controller do
  describe "post index" do
    it "returns a 201" do
      response = create_playlist.code
      expect(response).to eq(201)
    end
  end
end

playlist_id = JSON.parse(create_playlist)["id"]

# track id's which can be accessed via right click on spotify as mentioned in the spotify manual
first_track = "3uCth4TIWyeQDnj3YbAVQB"
second_track = "2fIBmScNzkGmSJ3y2XsmEI"
third_track = "7MufKxirS2VnFptXKAoiNK"

# post request o add tracks to my playlist and get a snapshot id as a response, which means it went successful
add_tracks = RestClient::Request.execute(method: "post",
                                         url: "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks",
                                         payload: {
                                           uris: %W[spotify:track:#{first_track} spotify:track:#{second_track} spotify:track:#{third_track}]
                                         }.to_json,
                                         headers: {
                                           "Authorization" => "Bearer #{access_token}",
                                           "Content-Type" => "application/json",
                                           "Accept" => "application/json"
                                         })

RSpec.describe "Successful request", type: :controller do
  describe "post index" do
    it "returns a 201" do
      response = add_tracks.code
      expect(response).to eq(201)
    end
  end
end

snapshot_id = JSON.parse(add_tracks)["snapshot_id"]

RSpec.describe Snapshot do
  context "snapshot id is given when an action is successfully performed" do
    it "checks if snapshot_id has a value" do
      snapshot = Snapshot.new(snapshot_id)
      snapshot.check_value
    end

    it "checks if it has the required number of characters" do
      expect(snapshot_id.length).to eq(56)
    end
  end
end


# put method to move the first track to the last position
reorder_tracks = RestClient::Request.execute(method: "put",
                                             url: "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks",
                                             payload: {
                                               range_start: 0,
                                               insert_before: 3,
                                               range_length: 2,
                                               snapshot_id: snapshot_id
                                             }.to_json,
                                             headers: {
                                               "Authorization" => "Bearer #{access_token}",
                                               "Content-Type" => "application/json",
                                               "Accept" => "application/json"
                                             })

RSpec.describe "Successful request", type: :controller do
  describe "put index" do
    it "returns a 200" do
      response = reorder_tracks.code
      expect(response).to eq(200)
    end
  end
end

# snapshot id is a proof that the last changes to the playlist were successful
snapshot_id = JSON.parse(reorder_tracks)["snapshot_id"]

RSpec.describe Snapshot do
  context "snapshot id is given when an action is successfully performed" do
    it "checks if snapshot_id has a value" do
      snapshot = Snapshot.new(snapshot_id)
      snapshot.check_value
    end

    it "checks if it has the required number of characters" do
      expect(snapshot_id.length).to eq(56)
    end
  end
end

# delete request to delete the last track form the playlist
delete_last = RestClient::Request.execute(method: "delete",
                                          url: "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks",
                                          payload: {
                                            tracks: [{
                                                       uri: "spotify:track:#{first_track}",
                                                       position: [2]
                                                     }],
                                            snapshot_id: snapshot_id
                                          }.to_json,
                                          headers: {
                                            "Authorization" => "Bearer #{access_token}",
                                            "Content-Type" => "application/json",
                                            "Accept" => "application/json"
                                          })

RSpec.describe "Successful request", type: :controller do
  describe "delete index" do
    it "returns a 200" do
      response = delete_last.code
      expect(response).to eq(200)
    end
  end
end

snapshot_id = JSON.parse(delete_last)["snapshot_id"]

RSpec.describe Snapshot do
  context "snapshot id is given when an action is successfully performed" do
    it "checks if snapshot_id is not null" do
      snapshot = Snapshot.new(snapshot_id)
      snapshot.check_value
    end

    it "checks if it has the required number of characters" do
      expect(snapshot_id.length).to eq(56)
    end
  end
end

# get request to get all the details of my playlist, including track's details
get_playlist = RestClient::Request.execute(method: "get",
                                           url: "https://api.spotify.com/v1/playlists/#{playlist_id}",
                                           params: {
                                             fields: "name,
                                                      description,
                                                      owner,
                                                      uri,
                                                      tracks.items(track(id, name, artists, album(name), uri))"
                                           }.to_json,
                                           headers: {
                                             "Authorization" => "Bearer #{access_token}",
                                             "Content-Type" => "application/json",
                                             "Accept" => "application/json"
                                           })

RSpec.describe "Successful request", type: :controller do
  describe "get index" do
    it "returns a 200" do
      response = get_playlist.code
      expect(response).to eq(200)
    end
  end
end

RSpec.describe CheckInfoPlaylist do
  describe "get playlist info" do
    it "checks if the playlist is not empty" do
      content_playlist = CheckInfoPlaylist.new
      content_playlist.add(get_playlist.body)
      expect(content_playlist.empty).to be(false)
    end
  end
end

# variables take the values needed for Playlist class
playlist_name = JSON.parse(get_playlist)["name"]
playlist_description = JSON.parse(get_playlist)["description"]
playlist_owner = JSON.parse(get_playlist)["owner"]["display_name"]
playlist_uri = JSON.parse(get_playlist)["external_urls"]["spotify"]
track_hash = [] # hash for storing each of the tracks

# loop to access both of the track details from the get request, if you change the loop iteration you can do that to not only 2 but more tracks
[0, 1].each do |i|
  # variables to store each track's details per iteration
  track_id = JSON.parse(get_playlist)["tracks"]["items"][i]["track"]["id"]
  track_name = JSON.parse(get_playlist)["tracks"]["items"][i]["track"]["name"]
  track_artist = JSON.parse(get_playlist)["tracks"]["items"][i]["track"]["artists"][0]["name"]
  album_name = JSON.parse(get_playlist)["tracks"]["items"][i]["track"]["album"]["name"]
  track_uri = JSON.parse(get_playlist)["tracks"]["items"][i]["track"]["external_urls"]["spotify"]

  # call the Track class to initialize it through variable t of type Track
  t = Track.new(track_id, track_name, track_artist, album_name, track_uri)
  t.add_hashes # stores the tracks
  track_hash[i] = t.json_result # converts the data stored into hash and json
  puts "track #{i} = ",  track_hash[i]
end

# make a variable p of type Playlist class and initializes it
p = Playlist.new(playlist_id, playlist_name, playlist_description, playlist_owner, playlist_uri, track_hash)
puts "Shows the populated playlist, the final output of the task = "
p.to_h_json # outputs the stored data in json format
