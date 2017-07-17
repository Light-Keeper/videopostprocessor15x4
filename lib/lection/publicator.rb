require 'chunky_png'
require_relative './general_info'

class Publicator
  attr_reader :workdir, :url_shortner

  def initialize(workdir, url_shortner)
    @workdir = workdir
    @url_shortner = url_shortner
  end

  def update_background(path)
    workdir.download('icon.png', './out/icon.png')
    process_images(path, './out/icon.png', './out/thumbnail.png')
    workdir.upload(path, 'background.png')
    workdir.upload('./out/thumbnail.png', 'thumbnail.png')
  end

  def generate_youtube_text
    info = GeneralInfo.new(workdir)

    info.slides = url_shortner.short workdir.presentation_url

    data = {
        lector_name: info.lector_name,
        lector_link: info.lector_link,
        description: info.description,
        slides: info.slides,
    }

    text = File.read('./view/youtube.txt')
    data.each do |key, value|
      text = text.gsub("{{#{key}}}", value)
    end

    info.youtube_text = text
  end

  private

  def process_images(bg_path, icon_path, res_path)
    bg = ChunkyPNG::Image.from_file(bg_path)
    icon = ChunkyPNG::Image.from_file(icon_path)
    res = (1000.downto 1).find {|x| x * 16 < bg.width && x * 9 < bg.height}
    new_w, new_h = res * 16, res * 9
    bg.crop!((bg.width - new_w) / 2, (bg.height - new_h) / 2, new_w, new_h)
    bg = bg.resize(1280, 720)
    bg.compose!(icon, 30, 30)
    bg.save(res_path)
  end
end
