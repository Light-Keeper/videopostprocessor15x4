require 'googl'
require_relative './google_accessor'

class LectionInfoAccessor

  def initialize(url)
    @url = url
    @google = GoogleAccessor.new
    @info = info_file
    @general = @info.worksheet_by_title 'general'
    raise "can not find general workshet in the info.gsheet" unless @general
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
    if  self.slides != ''
      puts 'slides url has already been set. skipping!'
      return
    end

    workdir =  @google.file_by_url @url
    presentation_dir = workdir.file_by_title 'presentation'
    files = presentation_dir.files
    raise 'presentation directory must have exactly 1 file or directory to share' unless files.size == 2
    to_share = files.find {|x| x.title != 'pages'}
    to_share.acl.push({type: 'anyone', role: 'reader'})

    self.slides = @google.shorten_url  to_share.human_url
  end

  def put_youtube_text
    data = {
        lector_name: self.lector_name,
        lector_link: self.lector_link,
        description: self.description,
        slides: self.slides,
    }

    text = File.read('./view/youtube.txt')
    data.each do |key, value|
      text = text.gsub("{{#{key}}}", value)
    end

    self.youtube_text = text
  end

  def lector_name()   find('Имя лектора')  end
  def lector_link()   find('ссылка на соцсеть лектора')  end
  def title()         find('Название')  end
  def description()   find('Описание')  end
  def slides()        find('Ссылка на слайды')  end
  def vk_event()      find('ссылки на ивент в вк')  end
  def ready_video()   find('готовое к публикации видео')  end
  def youtube_text()  find('текст для ютуба') end

  def name=(val)          set('Имя лектора', val)  end
  def lector_link=(val)   set('ссылка на соцсеть лектора', val)  end
  def title=(val)         set('Название', val)  end
  def description=(val)   set('Описание', val)  end
  def slides=(val)        set('Ссылка на слайды', val)  end
  def vk_event=(val)      set('ссылки на ивент в вк', val)  end
  def ready_video=(val)   set('готовое к публикации видео', val)  end
  def youtube_text=(val)  set('текст для ютуба', val) end

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
    row || raise("can not find row with title #{title} in the general workshet")
  end

  def info_file
    workdir =  @google.file_by_url @url
    res = workdir.spreadsheets.find {|s| s.title == "info"}
    res || raise('can not find info.gsheet!')
  end
end