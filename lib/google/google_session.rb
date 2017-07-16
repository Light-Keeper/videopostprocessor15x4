require 'google_drive'
require 'json'

class GoogleSession
  def initialize(credentials_path)
    @credentials = load_credentials(credentials_path)
  end

  def file_by_url(url)
    uri = URI.parse(url)
    if uri.query
      params = CGI::parse(uri.query)
      return drive_session.file_by_id params["id"][0] unless params["id"].empty?
    end
    drive_session.file_by_url url
  end

  def access_token
    @credentials.access_token
  end

  private

  def drive_session
    @drive_session ||= GoogleDrive::Session.new(@credentials)
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