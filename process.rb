require 'json'
require_relative 'lib/google_accessor'
require_relative 'lib/picture_generator'
require_relative 'lib/video_provider'
require_relative 'lib/cmd_arguments'
require_relative 'lib/ffmpeg'

options = CmdArgumens.new.options
out_dir = './out'
pic_out_dit = "#{out_dir}/pic"
view_dir = './view'

if options[:pic]
  raise "working directory URL must be specified" unless options[:id]
  google = GoogleAccessor.new(options[:id])
  generator = PictureGenerator.new(pic_out_dit,view_dir)
  generator.render_pictures google.extract_lection_data
end

raise "video URI must be present!" unless options[:video]
video_provider = VideoProvider.new
video = video_provider.getFile options[:video]

lection_data = JSON.parse File.read("#{pic_out_dit}/data.json")

ffmpeg = FFmpeg.new video,
                    "#{pic_out_dit}/title.png", lection_data['subs'],
                    small:options[:small], dry:options[:dry]

ffmpeg.render


