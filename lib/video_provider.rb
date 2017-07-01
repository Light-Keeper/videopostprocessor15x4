class VideoProvider

  def getFile( url )
    if File.file?(url)
      url
    else
      raise 'file not foud'
    end
  end
end