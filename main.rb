require "watir"
require "rest-client"
require "json"
require "rspec"
require "cgi"
require "uri"
require "pry"
require "rubocop"
require "date"

# setting up query parameters
client_id = "24453721197f430081da7ff7138abc80"
response_type = "code"
redirect_uri = "https://example.com/callback"
client_secret = "ef229a536b01493d856654d568488eb9"
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

# if you have auth-accept page then uncomment next two lines and delete the sleep between them! -- VERY IMPORTANT!

# browser.button(id: "auth-accept").wait_until_present(timeout: 3) # uncomment this if auth accept appears

sleep 1 # browser to not close in  # delete this if auth accept appears

#browser.button(id: "auth-accept").click # uncomment this if auth-accept appears

sleep 1

# get the authorization-code
res = CGI.parse(URI.parse(browser.url).query)
@authorization_code = res["code"]
puts "authorization_code = ", @authorization_code

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

access_token = JSON.parse(token)["access_token"]
puts "access token = ", access_token
refresh_token = JSON.parse(token)["refresh_token"]
puts "refresh token = ", refresh_token
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
  access_token = JSON.parse(new_token)["access_token"]
  puts "new access token = ", access_token
end

# get request to get user_id
profile = RestClient::Request.execute(method: "get",
                                      url: "https://api.spotify.com/v1/me",
                                      headers: {
                                        "Authorization" => "Bearer #{access_token}"
                                      })

user_id = JSON.parse(profile)["id"]
puts "user_id = ", user_id

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

playlist_id = JSON.parse(create_playlist)["id"]
puts "playlist_id = ", playlist_id

#track id's which can be accessed via right click on spotify as mentioned in the spotify manual
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

snapshot_id = JSON.parse(add_tracks)["snapshot_id"]
puts "add tracks request = ", add_tracks.body

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

# snapshot id is a proof that the last changes to the playlist went successful
snapshot_id = JSON.parse(reorder_tracks)["snapshot_id"]
puts "new snapshot id after reorder tracks = ", snapshot_id

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

snapshot_id = JSON.parse(delete_last)["snapshot_id"]
puts "new snapshot id after delete last track = ", snapshot_id

# creating a playlist class
class Playlist
  def initialize(id, name, description, owner_name, spotify_url, tracks)
    @id = id
    @name = name
    @description = description
    @owner_name = owner_name
    @spotify_url = spotify_url
    @tracks = tracks
  end

  # store the tracks into a hash and prints the hash converted into json
  def to_h_json
    hash = { name: @name.to_s, description: @description.to_s, owner_name: @owner_name.to_s, spotify_url: @spotify_url.to_s, id: @id.to_s, tracks: @tracks.to_s }
    puts hash.to_json
  end
end

# create a track class
class Track
  def initialize(id, name, artist_name, album_name, spotify_url)
    @id = id
    @name = name
    @artist_name = artist_name
    @album_name = album_name
    @spotify_url = spotify_url
    @array = []
  end

  # condition that verifies if array is empty, if it is it stores the first track details
  # if it's not empty then it has a track's details so it appends the details of the next tracks
  def add_hashes
    if @array.empty?
      @array = [name: @name.to_s, artist_name: @artist_name.to_s, album_name: @album_name.to_s, spotify_uri: @spotify_url.to_s, id: @id.to_s]
    else
      @array.append(name: @name.to_s, artist_name: @artist_name.to_s, album_name: @album_name.to_s, spotify_uri: @spotify_url.to_s, id: @id.to_s)
    end
  end

  # converts the array into hash and the outputs it in json
  def json_result
    hash = Hash(*@array)
    hash.to_json
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

puts "Get playlist details request body = ", get_playlist.body

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
