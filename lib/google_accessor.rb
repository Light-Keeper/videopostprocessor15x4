require 'google_drive'
require 'fileutils'
require 'json'

class GoogleAccessor
  attr_accessor :session

  def initialize()
    @credentials = load_credentials('./secret/google.json')
    @session = GoogleDrive::Session.new(@credentials)
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

  def shorten_url(long_url)
    res = HTTParty.post('https://www.googleapis.com//urlshortener/v1/url',
                        body: {longUrl:long_url}.to_json,
                        headers: {'Content-Type'.to_sym => 'application/json', :Authorization => 'Bearer ' + @credentials.access_token})
    raise "invalid shortner response: #{res}" unless res['id']
    res['id']
  end

  def load_credentials(path)
    config = JSON.parse File.read path

    credentials = Google::Auth::UserRefreshCredentials.new(
        client_id: config['client_id'],
        client_secret: config['client_secret'],
        scope: config['scope'],
        redirect_uri: 'urn:ietf:wg:oauth:2.0:oob')

    if config['refresh_token']
      credentials.refresh_token = config['refresh_token']
      credentials.fetch_access_token!
    else
      $stderr.print("\n1. Open this page:\n%s\n\n" % credentials.authorization_uri)
      $stderr.print('2. Enter the authorization code shown in the page: ')
      credentials.code = $stdin.gets.chomp
      credentials.fetch_access_token!
      config['refresh_token'] = credentials.refresh_token
    end

    ::File.open(path, 'w', 0600) { |f| f.write(JSON.pretty_generate(config)) }

    credentials
  end


end
