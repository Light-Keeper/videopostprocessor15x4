require_relative './google_accessor'

class LectionInfoAccessor

  def initialize(url)
    @url = url
    @google = GoogleAccessor.new
    @info = info_file
  end

  def lector_name
    find 'Имя лектора'
  end

  def title
    find 'Название'
  end

  def subs
    subtitles = @info.worksheet_by_title 'subtitles'

    (3..subtitles.num_rows).map {|i| {
        start:  subtitles[i, 1],
        end:    subtitles[i, 2],
        text:   subtitles[i, 3],
        id:     i
    }}

  end

  private

  def find(title)
    general = @info.worksheet_by_title 'general'
    raise "can not find general workshet in the info.gsheet" unless general

    row = (2..100).find {|i| general[i, 1].downcase.include? title.downcase}
    raise "can not find row with title #{title} in the general workshet" unless row

    general[row, 2]
  end

  def info_file
    workdir =  @google.file_by_url @url
    res = workdir.spreadsheets.find {|s| s.title == "info"}
    raise 'can not find info.gsheet!' unless res
    res
  end
end