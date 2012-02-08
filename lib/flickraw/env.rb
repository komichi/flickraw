module FlickRaw
  FlickRaw.api_key = ENV['FLICKRAW_API_KEY'] unless FlickRaw.api_key
  FlickRaw.shared_secret = ENV['FLICKRAW_SHARED_SECRET'] unless FlickRaw.shared_secret
  #FlickRaw.secure = true

  flickr.access_token = ENV['FLICKRAW_ACCESS_TOKEN'] unless flickr.access_token
  flickr.access_secret = ENV['FLICKRAW_ACCESS_SECRET'] unless flickr.access_secret
end

