require "google_drive"

class GoogleAccessor
  attr_accessor :session

  def initialize()
    @session = GoogleDrive::Session.from_config("./secret/config.json")
  end

  def download_file(url, where)
    file = file_by_url(url)
    res = "#{where}/#{file.id}_#{file.title}"
    tmp = "#{where}/tmp__#{file.id}_#{file.title}"

    `rm '#{tmp}'` if File.file? tmp

    if File.file?(res)
      puts "reusing cached file #{res}"
    else
      puts "donwloading file to #{res}"
      file.download_to_file(tmp)
      `mv '#{tmp}' '#{res}'`
    end

    res
  end

  def extract_lection_data(url)
    info = info_file(url)
    main_ws = info.worksheets[0]
    sub_ws = info.worksheets[1]

    {
        main: {
            name: main_ws[1, 2],
            title:  main_ws[2, 2]
        },

        subs: (3..sub_ws.num_rows).map { |row| {
            start: sub_ws[row,1],
            end:   sub_ws[row,2],
            text:  sub_ws[row,3],
            id:    row
          }
        }
    }
  end

  private

  def file_by_url(url)
    uri = URI.parse(url)

    if uri.query
      params = CGI::parse(uri.query)
      return @session.file_by_id params["id"][0] if params["id"]
    end

    @session.file_by_url url
  end

  def info_file(url)
    workdir =  file_by_url url
    res = workdir.spreadsheets.find {|s| s.title == "info"}
    raise 'can not find info.gsheet!' unless res
    res
  end

end
