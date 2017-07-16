require 'httparty'

class GoogleUrlShornter
  def initialize(session)
    @session = session
  end

  def short(long_url)
    res = HTTParty.post('https://www.googleapis.com//urlshortener/v1/url',
                        body: {longUrl:long_url}.to_json,
                        headers: {'Content-Type'.to_sym => 'application/json', :Authorization => 'Bearer ' + @session.access_token})
    raise "invalid shortner response: #{res}" unless res['id']
    res['id']
  end
end
