require_relative './google_session'
require_relative './google_url_shortner'
require_relative './google_wokdir'

class GoogleFactory

  def self.workdir(url)
    google_dir = default_session.file_by_url url
    GoogleWorkdir.new google_dir
  end

  def self.shortnter
    @@shornter ||= GoogleUrlShornter.new(default_session)
  end

  def self.default_session
    @@session ||= GoogleSession.new('./secret/google.json')
  end
end