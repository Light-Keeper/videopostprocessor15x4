require 'json'
require_relative 'lib/google_accessor'
require_relative 'lib/picture_generator'
require_relative 'lib/video_provider'
require_relative 'lib/cmd_arguments'
require_relative 'lib/ffmpeg'
require_relative 'lib/trello_accessor'

options = CmdArgumens.new.options

if options[:trello]
  trello = TrelloAccessor.new
  info = trello.card_info options[:trello]

  puts "trello info:"
  puts info

  options[:input] ||= info[:video]
  options[:workdir] ||= info[:workdir]
end


out_dir = './out'
pic_out_dit = "#{out_dir}/pic"
cache_dir = "#{out_dir}/cache"
dst = "#{out_dir}/res.mp4"
view_dir = './view'


if options[:pic]
  raise "working directory URL must be specified" unless options[:workdir]
  google = GoogleAccessor.new
  generator = PictureGenerator.new(pic_out_dit,view_dir)
  generator.render_pictures google.extract_lection_data(options[:workdir])
end

if options[:video]
  raise "video URI must be present!" unless options[:video]

  video_provider = VideoProvider.new(cache_dir)
  video = video_provider.getFile options[:input]

  lection_data = JSON.parse File.read("#{pic_out_dit}/data.json")
  ffmpeg = FFmpeg.new(video,
                      dst,
                      "#{pic_out_dit}/title.png",
                      lection_data['subs'],
                      small:options[:small], dry:options[:dry])
  ffmpeg.render
end



