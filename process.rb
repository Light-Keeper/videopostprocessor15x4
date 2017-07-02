require 'json'
require_relative 'lib/lection_info_accessor'
require_relative 'lib/picture_generator'
require_relative 'lib/video_provider'
require_relative 'lib/parameters'
require_relative 'lib/ffmpeg'

options = Parameters.new.options

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

if options[:publish]
  raise "working directory URL must be specified" unless options[:workdir]
  lection = LectionInfoAccessor.new(options[:workdir])
  lection.share_slides
end

