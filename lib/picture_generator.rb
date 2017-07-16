require 'json'
require 'imgkit'
require 'fileutils'

class PictureGenerator
  def initialize(dest)
    @destination = dest
  end

  def clear
    FileUtils.rm_rf @destination
  end

  def render_title(name, title)
    generic_generate('title', "#{@destination}/title.png", name:name, title:title)
  end

  def render_subs(subs)
    subs.each do |sub|
      sub[:path] = "#{@destination}/sub_#{sub[:id]}.png"
      generic_generate('subtitles', sub[:path], text:sub[:text])
    end
  end

  private

  def generic_generate(name, resultname, data = {})
    tmp = "#{@destination}/generate_#{name}"

    FileUtils.rm_rf tmp
    FileUtils.mkpath tmp
    FileUtils.cp_r "./view/#{name}/.", tmp, :verbose => false

    text = File.read("#{tmp}/index.html")
    data.each do |key, value|
      text = text.gsub("{{#{key}}}", value)
    end
    File.open("#{tmp}/index.html", "w") {|file| file.puts text }

    kit = IMGKit.new(File.new("#{tmp}/index.html"), transparent:true, quality:20, width:1920, height:1080)
    kit.to_file resultname
    FileUtils.rm_rf tmp
  end

end