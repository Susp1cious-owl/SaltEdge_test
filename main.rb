require 'watir'
require 'rest-client'
require 'json'
require 'rspec'
require 'cgi'
require 'uri'
require 'net/http'
#Requesting Authorization

#setting query parameters
client_id = '24453721197f430081da7ff7138abc80'
response_type = 'code'
redirect_uri = 'https://example.com/callback'
client_secret = 'ef229a536b01493d856654d568488eb9'

#creating the URL
url = "https://accounts.spotify.com/authorize?client_id=#{client_id}&response_type=#{response_type}&redirect_uri=#{redirect_uri}"

#authorizing using Watir
browser = Watir::Browser.new
browser.goto url

browser.text_field(id: "login-username").set("vadim.ojog@yahoo.com")
browser.text_field(id: "login-password").set("1234567000")
browser.button(id: "login-button").click

# browser.button(id: "auth-accept").wait_until_present(timeout: 3)

sleep 1

browser.button(id: "auth-accept").click

sleep 1

res = CGI.parse(URI.parse(browser.url).query)
@authorization_code = res["code"]
puts @authorization_code

#url in variables
response = RestClient::Request.execute(method: 'post',
                                       url: 'https://accounts.spotify.com/api/token',
                                       payload: {
                                         'grant_type' => "authorization_code",
                                         'code' => @authorization_code[0],
                                         'redirect_uri' => redirect_uri,
                                         'client_id' => client_id,
                                         'client_secret' => client_secret
                                       })

access_token = JSON.parse(response)['access_token']
puts access_token
refresh_token = JSON.parse(response)['refresh_token']

puts 'Bearer' + access_token
profile = RestClient::Request.execute(method: 'get',
                                     url: 'https://api.spotify.com/v1/me',
                                      headers:{
                                        'Authorization' => 'Bearer ' + access_token,
                                        # Accept: 'application/json',
                                        # Content-Type: 'application/json'
                                      }) { |response, request, result|

  puts response
  puts request
  puts result
}

# "Accept: application/json" -H "Content-Type: application/json

puts profile.body


#Authorization: Basic *<base64 encoded client_id:client_secret>*

#RestClient.post('https://accounts.spotify.com/api/token', payload: grant_type = authorization_code, code , redirect_uri , headers ={ Authorization: Basic *<base64 encoded client_id:client_secret>*)

# https://example.com/callback?code=AQDx3uLGRtEtrk6MazV9QGX4Ga3k7oOzf1-hoAM0uI1P01W6mHrj6u1Cu5BJ-kjanZixw3Pfu6JgH2y87gHYEhWQjfRvg0EKX8xlNjZ50tg95bCPFyykoYZr_Igwn6jtXwlFZQ4j0IXQILv3PIlON1xg6VaI1yvPehEzfDK3CiE
