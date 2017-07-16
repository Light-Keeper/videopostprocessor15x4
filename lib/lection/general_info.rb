class GeneralInfo
  attr_reader :workdir

  def initialize(workdir)
    @workdir = workdir
  end

  def subs
    subtitles = workdir.info.worksheet_by_title 'subtitles'
    (3..subtitles.num_rows).map {|i| {
        start:  subtitles[i, 1],
        end:    subtitles[i, 2],
        text:   subtitles[i, 3],
        id:     (i - 2).to_s.rjust(2, "0")
    }}
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
    @general ||= workdir.info.worksheet_by_title('general') or raise 'can not find general workshet in the info.gsheet'
  end
end
