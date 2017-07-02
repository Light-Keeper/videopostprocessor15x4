require "google_drive"
require 'fileutils'

class GoogleAccessor
  attr_accessor :session

  def initialize()
    @session = GoogleDrive::Session.from_config("./secret/config.json")
  end

  def download_file(url, where)
    file = file_by_url(url)
    res = "#{where}/#{file.id}_#{file.title}"
    tmp = "#{where}/tmp__#{file.id}_#{file.title}"

    FileUtils.remove tmp if File.file? tmp

    if File.file?(res)
      puts "reusing cached file #{res}"
    else
      puts "donwloading file to #{res}"
      file.download_to_file(tmp)
      FileUtils.move tmp, res
    end

    res
  end


  def file_by_url(url)
    uri = URI.parse(url)

    if uri.query
      params = CGI::parse(uri.query)
      return @session.file_by_id params["id"][0] if params["id"]
    end

    @session.file_by_url url
  end

end
