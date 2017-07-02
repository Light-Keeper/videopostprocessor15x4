require_relative './google_accessor'
require 'googl'

class LectionInfoAccessor

  def initialize(url)
    @url = url
    @google = GoogleAccessor.new
    @info = info_file
    @general = @info.worksheet_by_title 'general'
    raise "can not find general workshet in the info.gsheet" unless @general
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

  def share_slides
    if  find('Ссылка на слайды') != ''
      puts "slides url has already been set. skipping!"
      return
    end

    workdir =  @google.file_by_url @url
    presentation_dir = workdir.file_by_title 'presentation'
    files = presentation_dir.files
    raise 'presentation directory must have exactly 1 file or directory to share' unless files.size == 2
    to_share = files.find {|x| x.title != 'pages'}
    to_share.acl.push({type: "anyone", role: "reader"})

    url = @google.shorten_url  to_share.human_url
    set('Ссылка на слайды', url)
  end

  private

  def set(title, value)
    row = find_row title
    @general[row, 2] = value
    @general.save
  end

  def find(title)
    @general[find_row(title), 2]
  end

  def find_row(title)
    row = (2..100).find {|i| @general[i, 1].downcase.include? title.downcase}
    raise "can not find row with title #{title} in the general workshet" unless row
    row
  end

  def info_file
    workdir =  @google.file_by_url @url
    res = workdir.spreadsheets.find {|s| s.title == "info"}
    raise 'can not find info.gsheet!' unless res
    res
  end
end