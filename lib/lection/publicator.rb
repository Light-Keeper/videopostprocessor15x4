require_relative './general_info'

class Publicator
  attr_reader :workdir, :url_shortner

  def initialize(workdir, url_shortner)
    @workdir = workdir
    @url_shortner = url_shortner
  end

  def update_background(path)
    workdir.download('icon.png', './out/icon.png')
    `ffmpeg -i #{path} -i ./out/icon.png -filter_complex '[0:0] scale=1280:720 [b];[b][1:0]overlay=x=30:y=30' -y ./out/thumbnail.png`
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
end
