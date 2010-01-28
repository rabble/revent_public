class Embed < ActiveRecord::Base
  belongs_to :report
  validates_presence_of :html

  before_create :extract_youtube_video_id
  def extract_youtube_video_id
    require 'hpricot'
    doc = Hpricot(html)
    params_movie = doc.at "param[@name=movie]"
    embed = doc.at "embed"
    uri = params_movie['value'] if params_movie && params_movie['value'] =~ /youtube.com/
    uri ||= embed['src'] if embed && embed['src'] =~ /youtube.com/
    return unless uri
    youtube_video_id = uri.split('/').last.split('&').first
    self.youtube_video_id ||= youtube_video_id
  end
  
  def youtube_thumbnail_url
    if self.youtube_video_id
      "http://i.ytimg.com/vi/#{self.youtube_video_id}/default.jpg"
    end
  end
  
  def youtube_video_url
    if self.youtube_video_id
      "http://www.youtube.com/watch?v=#{self.youtube_video_id}"
    end
  end

  attr_accessor :tag_depot
end
