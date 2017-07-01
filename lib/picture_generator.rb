require 'json'
require 'imgkit'

class PictureGenerator
  attr_accessor :destination

  def initialize(destination, views)
    @destination = destination
    @views = views
  end

  def render_pictures(lection_data)
    lection_data[:subs].map {|s| s[:path] = "#{@destination}/sub_#{s[:id]}.png"}

    p lection_data

    `rm -rf #{@destination}`
    `mkdir -p #{@destination}`
    generic_generate('title', "#{@destination}/title.png", lection_data[:main])
    lection_data[:subs].each do |sub|
      generic_generate('subtitles', sub[:path], text:sub[:text])
    end

    File.open("#{@destination}/data.json", 'w') { |file| file.write(lection_data.to_json) }
  end

  private

  def generic_generate(name, resultname, data = {})
    tmp = "#{@destination}/generate_#{name}"
    `rm -rf #{tmp}`
    `cp -r #{@views}/#{name} #{tmp}`

    text = File.read("#{tmp}/index.html")
    data.each do |key, value|
      text = text.gsub("{{#{key}}}", value)
    end
    File.open("#{tmp}/index.html", "w") {|file| file.puts text }

    kit = IMGKit.new(File.new("#{tmp}/index.html"), transparent:true, quality:20)
    kit.to_file resultname
    `rm -rf #{tmp}`
  end

end