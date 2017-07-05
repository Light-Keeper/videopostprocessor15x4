require 'fileutils'
require_relative './google_accessor'

class VideoProvider
  attr_accessor :cache

  def initialize(cache)
    @cache = cache
    FileUtils.mkpath cache
  end

  def get_file( url )
    plain_file(url) || google_drive_video(url) || unsupported(url)
  end

  def plain_file(url)
    File.file?(url) && url
  end

  def google_drive_video(url)
    url.start_with?('https://drive.google.com') &&
        GoogleAccessor.new.download_file(url, cache )
  end

  def unsupported(url)
    raise 'don\'t know how to download this file: ' + url
  end
end