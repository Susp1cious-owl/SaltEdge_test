
#Requesting Authorization

#setting query parameters
CLIENT_ID = '0fd16b82976f4a6aaf1520ee9d1f720e'

RESPONSE_TYPE = 'code'
REDIRECT_URI = 'https://spotify.com/'

#creating the URL
URL = "https://accounts.spotify.com/authorize?client_id=#{CLIENT_ID}&response_type=#{RESPONSE_TYPE}&redirect_url=#{REDIRECT_URI}"

#authorizing using Watir
Watir::Browser.start URL

#puts browser.url

# browser.close