require 'json'
require_relative 'lib/lection_info_accessor'
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

  options[:video] ||= info[:video]
  options[:workdir] ||= info[:workdir]
end

out_dir = './out'
dst = options[:output] || out_dir + '/res.mp4'

pictures = PictureGenerator.new("#{out_dir}/pic",'./view')

if options[:pic]
  raise "working directory URL must be specified" unless options[:workdir]
  lection = LectionInfoAccessor.new(options[:workdir])

  pictures.clear
  pictures.render_title lection.lector_name, lection.title
  pictures.render_subs lection.subs
end

if options[:convert]
  raise "video URI must be present!" unless options[:video]
  video = VideoProvider.new("#{out_dir}/cache").getFile options[:video]

  ffmpeg = FFmpeg.new(video,
                      dst,
                      pictures.rendered_title_path,
                      pictures.rendered_subs,
                      options)
  ffmpeg.render
end



