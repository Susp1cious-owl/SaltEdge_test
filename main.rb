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
                                        'Authorization' => 'Bearer ' + access_token,
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


playlist = RestClient::Request.execute(method: 'post',
                                       url: "https://api.spotify.com/v1/users/#{user_id}/playlists",
                                       payload: {
                                         'name' => 'My new playlist',
                                         'description' => 'New playlist description',
                                         'public' => false
                                       },
                                       headers: {
                                         'Authorization' => 'Bearer ' + access_token
                                       })


