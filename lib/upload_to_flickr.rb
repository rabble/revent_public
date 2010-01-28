require 'site'
require 'attachment'
require 'logger'

def upload_images_to_flickr(attachments, options = {})
  log = Logger.new(File.expand_path(File.dirname(__FILE__) + '/../log/flickr.log'), 5, 10*1024)
  log.level = Logger::INFO
  log.debug("Uploading to flickr...")
  unless options.empty?
    options.symbolize_keys
    # if options[:async] not specified, default to async=true
    async = options[:async].nil? ? true : options[:async]
    site_id = options[:site_id] || Site.current
    title = options[:title]
    tags = options[:tags]
    photoset = options[:photoset]
  end

  flickr = Site.flickr 
  return unless flickr
  attachments.each do |attachment|
    begin
      data = attachment.temp_data
      data ||= File.read(attachment.full_filename) if File.exists?(attachment.full_filename)
      data ||= open(attachment.public_filename).read
    	if async
    	  photo_id = flickr.photos.upload.upload_image_async(data, attachment.content_type, attachment.filename, title, attachment.caption, tags)
	  log.debug("uploaded async...")
    	else
    	  photo_id = flickr.photos.upload.upload_image(data, attachment.content_type, attachment.filename, title, attachment.caption, tags)
	  log.info("uploaded photo_id: #{photo_id}")
	  attachment.update_attribute(:flickr_id, photo_id)
	  flickr.photosets.addPhoto(photoset, photo_id) if (photoset and attachment.primary?)  # photoset = '72157602812476432'
	  log.info("added to photoset: #{photoset}")
    	end
    rescue XMLRPC::FaultException
    end
  end
end
