require 'imgkit'
require 'optparse'
require "google_drive"
require 'json'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: process.rb [options]"
  opts.on('-p', '--pic', 'rebuild all pictutes') { || options[:pic] = true }
  opts.on('-i', '--id=ID', 'google directoty id') { |p| options[:id] = p }
  opts.on('-v', '--video=URI', 'URI of video') { |p| options[:video] = p }
  opts.on('-d', '--dry', 'ffmpeg dry run') { |p| options[:dry] = true }
  opts.on('-s', '--small', 'generate small video') { |p| options[:small] = true }
end.parse!

unless options[:id]
  raise "working directory URL must be specified"
end

unless options[:video]
  raise "video URI must be present!"
end

#-------------------------------------------------------------------------------

def generic_generate(name, resultname, data = {})
  tmp = "./out/pic/generate_#{name}"
  `rm -rf #{tmp}`
  `cp -r ./view/#{name} #{tmp}`

  text = File.read("#{tmp}/index.html")
  data.each do |key, value|
    text = text.gsub("{{#{key}}}", value)
  end
  File.open("#{tmp}/index.html", "w") {|file| file.puts text }

  kit = IMGKit.new(File.new("#{tmp}/index.html"), transparent:true, quality:20)
  kit.to_file resultname
  `rm -rf #{tmp}`
end

class GoogleAccessor
  attr_accessor :session
  attr_accessor :url

  def initialize(url)
    @session = GoogleDrive::Session.from_config("./secret/config.json")
    @url = url
  end

  def extract_lection_data()
    info = info_file
    main_ws = info.worksheets[0]
    sub_ws = info.worksheets[1]

     {
        main: {
            name: main_ws[1, 2],
            title:  main_ws[2, 2]
        },

        subs: (3..sub_ws.num_rows).map { |row| {
            start: sub_ws[row,1],
            end:   sub_ws[row,2],
            text:  sub_ws[row,3],
            id:    row
          }
        }
    }
  end

  def info_file
    workdir = session.collection_by_url(url)
    res = workdir.spreadsheets.find {|s| s.title == "info"}
    raise 'can not find info.gsheet!' unless res
    res
  end

  def render_pictures()
    lection_data = self.extract_lection_data
    lection_data[:subs].map {|s| s[:path] = "./out/pic/sub_#{s[:id]}.png"}

    p lection_data

    `rm -rf ./out/pic`
    `mkdir -p out/pic`
    generic_generate('title', './out/pic/title.png', lection_data[:main])
    lection_data[:subs].each do |sub|
      generic_generate('subtitles', sub[:path], text:sub[:text])
    end

    File.open('./out/pic/data.json', 'w') { |file| file.write(lection_data.to_json) }
  end
end

def download_video(url)
  if File.file?(url)
    url
  else
    raise 'file not foud'
  end
end

class FFmpeg
  def initialize(video, title, subs, params = {})
    @video = video
    @title = title
    @subs = subs
    @params = params
  end

  def render
    cmd = construct_cmd
    p ""
    p cmd
    system cmd unless @params[:dry]
  end

  def render_cmd_only
    cmd = construct_cmd
    p ""
    p cmd
  end

  def construct_cmd
    fill_fade_options @subs

    inputs = " -i '#{@video}'"
    inputs += ' -i ./view/intro.mp4'
    inputs += ' -i ./view/outro.mp4'

    inputs += " -loop 1 -i '#{@title}'"
    inputs += @subs.map {|s| " -loop 1 -i '#{s['path']}'"} .join(' ')


    filters = ''

    if @params[:small]
      filters += '[0:v] scale=320:180,fifo [main];'
      filters += '[1:v] scale=320:180 [intro];'
      filters += '[2:v] scale=320:180 [outro];'
    else
      filters += '[0:v] copy,fifo [main];'
      filters += '[1:v] copy [intro];'
      filters += '[2:v] copy [outro];'
    end

    filters += '[0:a] loudnorm [amain];'
    filters += '[1:a] loudnorm [aintro];'
    filters += '[2:a] loudnorm [aoutro];'

    filters += "[3:0] #{picture_filter 0, 6, true, true} [title];"

    filters += filtered_subs {|s, i|
      "[#{i + 4}:0] #{picture_filter s['start'], s['end'], s['fadein'], s['fadeout']} [sub#{i}];"
    }

    filters += "[main][title] overlay=eof_action=pass:repeatlast=0 [tmp0];"
    filters += filtered_subs { |s, i| "[tmp#{i}][sub#{i}] overlay=eof_action=pass:repeatlast=0 [tmp#{i + 1}];" }

    filters += "[tmp#{@subs.size}] copy [lection];"
    filters += "[intro] [aintro] [lection] [amain] [outro] [aoutro] concat=n=3:v=1:a=1"

    %{ffmpeg #{inputs}  -filter_complex "#{filters}" -y ./out/res.mp4 }.gsub(/\s+/, ' ').strip
  end

  def filtered_subs (&block)
    (@subs.map.with_index &block).join(' ')
  end

  def picture_filter(from, to, fadein, fadeout)
    from = time_to_secons(from).round(1)
    len = (time_to_secons(to) - from).round(1)

    fadein = fadein ? 'fade=t=in:st=0:d=0.2:alpha=1,' : ''
    fadeout = fadeout ? "fade=t=out:st=#{(len - 0.2).round(1)}:d=0.2:alpha=1," : ''

    scale = @params[:small] ? 'scale=320:180,' : ''

    "trim=duration=#{len},#{scale}format=rgba,#{fadein}#{fadeout}setpts=PTS+#{from}/TB"
  end

  def time_to_secons(time)
    return time if time.is_a? Integer
    return time if time.is_a? Float
    s = time.split(':').map {|v| v.to_f}

    return s[0] if s.size == 1
    return s[1] + s[0] * 60 if s.size == 2
    return s[2] + s[1] * 60 + s[0] * 60 * 60 if s.size == 3
    raise "time format not supported"
  end

  def fill_fade_options(subs)
    subs.each {|s| s['fadein'] = true, s['fadeout'] = true}
  end
end
#-------------------------------------------------------------------------------

video = download_video options[:video]

if options[:pic]
  google = GoogleAccessor.new(options[:id])
  google.render_pictures
end

lection_data = JSON.parse File.read("./out/pic/data.json")

ffmpeg = FFmpeg.new(video, './out/pic/title.png', lection_data['subs'], small:options[:small])

if options[:dry]
  ffmpeg.render_cmd_only
else
  ffmpeg.render
end


