require 'watir'
require 'rest-client'
require 'json'
require 'rspec'
require 'cgi'
require 'uri'
require 'net/http'
require 'pry'
require 'rubocop'
# Requesting Authorization

# setting query parameters
client_id = '24453721197f430081da7ff7138abc80'
response_type = 'code'
redirect_uri = 'https://example.com/callback'
client_secret = 'ef229a536b01493d856654d568488eb9'
scope = 'playlist-modify-public playlist-modify-private'

# creating the URL
url = "https://accounts.spotify.com/authorize?client_id=#{client_id}&response_type=#{response_type}&redirect_uri=#{redirect_uri}&scope=#{scope}"

# authorizing using Watir
browser = Watir::Browser.new
browser.goto url

browser.text_field(id: 'login-username').set('vadim.ojog@yahoo.com')
browser.text_field(id: 'login-password').set('12345670000')
browser.button(id: 'login-button').click

# browser.button(id: "auth-accept").wait_until_present(timeout: 3)

sleep 1

# browser.button(id: 'auth-accept').click

sleep 1

res = CGI.parse(URI.parse(browser.url).query)
@authorization_code = res['code']
puts @authorization_code

# url in variables
token = RestClient::Request.execute(method: 'post',
                                    url: 'https://accounts.spotify.com/api/token',
                                    payload: {
                                      'grant_type' => 'authorization_code',
                                      'code' => @authorization_code[0],
                                      'redirect_uri' => redirect_uri,
                                      'client_id' => client_id,
                                      'client_secret' => client_secret
                                    })

access_token = JSON.parse(token)['access_token']
puts access_token
refresh_token = JSON.parse(token)['refresh_token']
expiry_time = JSON.parse(token)['expires_in']  # authorization code becomes refresh token


if expiry_time < 500
  new_token = RestClient::Request.execute(method: 'post',
                                          url: 'https://accounts.spotify.com/api/token',
                                          payload: {
                                            'grant_type' => refresh_token,
                                            'refresh_token' => refresh_token,
                                            'client_id' => client_id,
                                            'client_secret' => client_secret
  })
  access_token = JSON.parse(new_token)['access_token']
end

puts 'Bearer ' + access_token
profile = RestClient::Request.execute(method: 'get',
                                      url: 'https://api.spotify.com/v1/me',
                                      headers: {
                                        'Authorization' => "Bearer #{access_token}" ,
                                        # Accept: 'application/json',
                                        # Content-Type: 'application/json'
                                      }) # { |response, request, result|

# puts response
# user_id = JSON.parse(response)['id']
# puts request
# puts result
# }

user_id = JSON.parse(profile)['id']
puts user_id

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
puts create_playlist.body
playlist_id = JSON.parse(create_playlist)['id']
puts playlist_id

first_track = '3uCth4TIWyeQDnj3YbAVQB'
second_track = '2fIBmScNzkGmSJ3y2XsmEI'
third_track = '7MufKxirS2VnFptXKAoiNK'

add_tracks = RestClient::Request.execute(method: "post",
                                         url: "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks",
                                         payload: {
                                           "uris": ["spotify:track:#{first_track}",
                                                    "spotify:track:#{second_track}",
                                                    "spotify:track:#{third_track}"]
                                           #postion add? still works on postman with value of 2
                                         }.to_json,
                                         headers: {
                                           "Authorization" => "Bearer #{access_token}",
                                           "Content-Type" => "application/json",
                                           "Accept" => "application/json"
                                         })

snapshot_id = JSON.parse(add_tracks)['snapshot_id']

puts snapshot_id

reorder_tracks = RestClient::Request.execute(method: "put",
                                             url: "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks",
                                             payload: {
                                               "range_start": 0,
                                               "insert_before": 3,
                                               "range_length": 2,
                                               "snapshot_id": snapshot_id
                                             }.to_json,
                                             headers: {
                                               "Authorization" => "Bearer #{access_token}",
                                               "Content-Type" => "application/json",
                                               "Accept" => "application/json"
                                             })

snapshot_id = JSON.parse(reorder_tracks)['snapshot_id']
puts snapshot_id # works -> gooood
puts "snapshot_id": snapshot_id

delete_last = RestClient::Request.execute(method: "delete",
                                          url: "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks",
                                          payload: {
                                            "tracks": [{
                                                         "uri": "spotify:track:#{first_track}",
                                                         "position": [2]
                                                       }],
                                            "snapshot_id": snapshot_id
                                          }.to_json,
                                          headers: {
                                            "Authorization" => "Bearer #{access_token}",
                                            "Content-Type" => "application/json",
                                            "Accept" => "application/json"
                                          })

snapshot_id = JSON.parse(delete_last)['snapshot_id']
puts snapshot_id

class Playlist
  def initialize(id, name, description, owner_name, spotify_url, tracks)
    @id     = id
    @name   = name
    @description = description
    @owner_name = owner_name
    @spotify_url = spotify_url
    @tracks = tracks
  end
end

get_playlist = RestClient::Request.execute(method: "get",
                                           url: "https://api.spotify.com/v1/playlists/#{playlist_id}",
                                           params: {
                                             "fields": "name,
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

puts get_playlist.body

playlist_name = JSON.parse(get_playlist)['name']
playlist_description = JSON.parse(get_playlist)['description']
playlist_owner = JSON.parse(get_playlist)['owner']
playlist_uri = JSON.parse(get_playlist)['uri']

#Playlist(playlist_id, playlist_name, playlist_description, playlist_owner, playlist_uri, Track)

=begin
for each track do
Track(a,b,c,d)
Playlist(a, b, c, Track)
=end


track_id = JSON.parse(get_playlist)['tracks.0.items.id']
puts track_id
track_name = JSON.parse(get_playlist)['items.0.tracks.name']
puts track_name
track_artist = JSON.parse(get_playlist)['items.0.artists.0.name']
puts track_artist
album_name = JSON.parse(get_playlist)['track.album.name']
puts album_name
track_uri = JSON.parse(get_playlist)['track.uri']
puts track_uri



class Track
  def initialize(id, name, artist_name, album_name, spotify_url)
    @id     = id
    @name   = name
    @artist_name = artist_name
    @album_name = album_name
    @spotify_url = spotify_url
  end
end
