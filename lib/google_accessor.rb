require "google_drive"

class GoogleAccessor
  attr_accessor :session
  attr_accessor :url

  def initialize(url)
    @session = GoogleDrive::Session.from_config("./secret/config.json")
    @url = url
  end

  def extract_lection_data()
    info = info_file
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

  def info_file
    workdir = session.collection_by_url(url)
    res = workdir.spreadsheets.find {|s| s.title == "info"}
    raise 'can not find info.gsheet!' unless res
    res
  end

end
