#!/usr/bin/env ruby

# add_machine_tags.rb
#
# this script determines the set of photos without md5 and sha1
# machine tags and then adds such tags for those photos

require 'rubygems'
require './flickraw'
require './flickraw/env'
require 'digest/sha1'
require 'digest/md5'
require 'fileutils'

be_quiet = false

# grabs all photos in the current user's photo stream (in date taken order)
# requires checksum tags if requested
def flickr_all_photos(with_machine_tags = false)
  all_photos = { }
  curr_page = 0
  params = { :user_id => 'me',
             :sort => 'date-taken-asc',
             :per_page => 500,
             :page => curr_page }
  if with_machine_tags
    params[:machine_tags] = 'checksum:md5=,checksum:sha1='
    params[:machine_tag_mode] = 'all'
  end
  loop do
    curr_photos = flickr.photos.search(params)
    break unless curr_photos && (curr_photos.size > 0)
    curr_photos.each { |photo| all_photos[photo['id']] = photo }
    curr_page += 1
    params[:page] = curr_page
  end
  all_photos
end

def flickr_all_photos_without_machine_tags
  $stderr.print "Grabbing All Photos ... "
  all_photos = flickr_all_photos
  $stderr.print "Done (#{all_photos.size.to_s} total) ... Grabbing Tagged Photos ... "
  tag_photos = flickr_all_photos(true)
  $stderr.print "Done (#{tag_photos.size.to_s} total) ... "
  all_photos.reject! { |id, photo| tag_photos.has_key?(id) }
  $stderr.puts "Tagging #{all_photos.size.to_s} Photos!"
  all_photos
end

# for each photo without machine tags
flickr_all_photos_without_machine_tags.values.each { |photo|
#       form the url for the original photo
  begin
    photo_file = "/tmp/" + photo['id'] + ".jpg"
    photo_info = flickr.photos.getInfo(:photo_id => photo['id'])
    photo_url = FlickRaw.url_o(photo_info)
    $stderr.puts 'Downloading url=' + photo_url + 
                 ' (title=' + photo['title'] + ') ... ' unless be_quiet
#       download the original photo
    `curl -# --location -o #{photo_file} #{photo_url}`
    raise Exception.new('download failed!') unless $? == 0
#       form the md5 and sha1 checksums
    sha1sum = md5sum = nil
    File.open(photo_file) { |f|
      s = f.read
      sha1sum = Digest::SHA1.hexdigest s
      md5sum  = Digest::MD5.hexdigest s
    }
#       add the md5 and sha1 checksums as machine tags
    $stderr.print 'Setting MD5 Tag ... ' unless be_quiet
    flickr.photos.addTags({ :photo_id => photo['id'], 
                            :tags => 'checksum:md5=' + md5sum })
    $stderr.print 'Done ... Setting SHA-1 Tag ... ' unless be_quiet
    flickr.photos.addTags({ :photo_id => photo['id'], 
                            :tags => 'checksum:sha1=' + sha1sum })
    $stderr.puts 'Done!' unless be_quiet
  rescue Exception => e
    $stderr.puts "warning: failed to download photo #{photo['id']} (title #{photo['title']}): " + e
  ensure
    FileUtils.rm(photo_file) if File.exists?(photo_file)
  end
}

