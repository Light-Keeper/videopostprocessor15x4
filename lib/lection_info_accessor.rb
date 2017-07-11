require 'googl'
require_relative './google_accessor'
require_relative './file_format_utils'

class LectionInfoAccessor
  include FileFormatUtils
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def subs
    shift_subs
    subtitles = info_file.worksheet_by_title 'subtitles'
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

    presentation_dir = workdir.file_by_title 'presentation'
    files = presentation_dir.files
    raise 'presentation directory must have exactly 1 file or directory to share' unless files.size == 2
    to_share = files.find {|x| x.title != 'pages'}
    to_share.acl.push({type: 'anyone', role: 'reader'})

    self.slides = google.shorten_url  to_share.human_url
  end

  def patch_background
    icon = workdir.file_by_title 'icon.png'
    background = workdir.file_by_title 'background.png'

    unless icon && background
      puts 'can not find icon.png or background.png. skipping...'
      return
    end

    icon_path = './out/icon.png'
    bg_path = './out/background.png'
    thumb_path = './out/thumbnail.png'

    File.delete(thumb_path) if File.exist?(thumb_path)
    icon.download_to_file(icon_path)
    background.download_to_file(bg_path)

    crop = get_crop_to_16x9_filter bg_path
    `ffmpeg -i #{bg_path} -i #{icon_path} -filter_complex '[0:0] #{crop},scale=1280:720 [b];[b][1:0]overlay=x=30:y=30' -y ./out/thumbnail.png`

    workdir.upload_from_file(thumb_path, 'thumbnail.png', :convert => false)
    puts 'thumbnail.png generated!'
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

  def shift_subs
    subtitles = info_file.worksheet_by_title 'subtitles'
    shift = subtitles[2,5]
    return if shift == ''
    shift = shift.to_f

    (3..subtitles.num_rows).map do |i|
      start = time_to_secons(subtitles[i, 1]) + shift
      fin = time_to_secons(subtitles[i, 2]) + shift

      subtitles[i, 1] = sec_to_time(start)
      subtitles[i, 2] = sec_to_time(fin)
    end

    subtitles[2,5] = ''
    subtitles.save
  end

  #TODO: move to semarate file and reuse
  def time_to_secons(time)
    return time if time.is_a? Integer
    return time if time.is_a? Float
    raise 'time has not been set' if time == ''

    s = time.split(':').map {|v| v.to_f}

    return s[0] if s.size == 1
    return s[1] + s[0] * 60 if s.size == 2
    return s[2] + s[1] * 60 + s[0] * 60 * 60 if s.size == 3
    raise 'time format not supported'
  end

  def sec_to_time(sec)
    h = (sec / 60 / 60).floor.to_s.rjust(2, '0')
    m = (sec / 60 - h.to_f * 60).floor.to_s.rjust(2, '0')
    s = (sec - m.to_f * 60 - h.to_f * 60 * 60).floor.to_s.rjust(2, '0')

    res =  h == "00" ? "#{m}:#{s}" : "#{h}:#{m}:#{s}"
  end

  def set(title, value)
    general[find_row(title), 2] = value
    general.save
  end

  def find(title)
    general[find_row(title), 2]
  end

  def find_row(title)
    row = (2..100).find {|i| general[i, 1].downcase.include? title.downcase}
    row or raise "can not find row with title #{title} in the general workshet"
  end

  def general
    @general ||= info_file.worksheet_by_title('general') or raise 'can not find general workshet in the info.gsheet'
  end

  def info_file
    @info_file ||= workdir.spreadsheets.find {|s| s.title == "info"} or raise 'can not find info.gsheet!'
  end

  def workdir
    @workdir ||=  google.file_by_url url
  end

  def google
    @google ||= GoogleAccessor.new
  end


end