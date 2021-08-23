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

