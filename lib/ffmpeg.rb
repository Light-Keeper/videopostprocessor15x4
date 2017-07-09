require_relative './file_format_utils'

class FFmpeg
  include FileFormatUtils

  def initialize(video, dst, title, subs, params = {})
    @video = video
    @title = title
    @subs = subs
    @params = params
    @dst = dst
  end

  def render
    cmd = construct_cmd
    puts '-------------------------------------------------------------------------'
    puts cmd
    puts '-------------------------------------------------------------------------'
    system cmd unless @params[:dry]
  end

  def construct_cmd
    %{ffmpeg #{all_inputs}  -filter_complex "#{all_filters}" -y '#{@dst}' }.gsub(/\s+/, ' ').strip
  end

  def all_inputs
    " -i '#{@video}'" +
    " -i './view/intro.mp4'" +
    " -i './view/outro.mp4'" +
    " -loop 1 -i '#{@title}'" +
    @subs.map {|s| " -loop 1 -i '#{s['path']}'"} .join(' ')
  end

  def all_filters
    "#{basic_input_filteting}#{picture_input_filters}#{overlay}#{concat}"
  end

  def basic_input_filteting
    "[0:v] #{get_crop_to_16x9_filter @video},#{input_video_filter} [main];" +
    "[1:v] #{input_video_filter} [intro];" +
    "[2:v] #{input_video_filter} [outro];" +
    '[0:a] loudnorm [amain];' +
    '[1:a] loudnorm [aintro];' +
    '[2:a] loudnorm [aoutro];'
  end

  def picture_input_filters
    "[3:0] #{picture_filter 0, 6} [title];" +
    @subs.each_with_index.map {|s, i| "[#{i + 4}:0] #{picture_filter s['start'], s['end']} [sub#{i}];" }.join(' ')
  end

  def overlay
    '[main][title] overlay=eof_action=pass:repeatlast=0 [tmp0];' +
    @subs.each_with_index.map { |s, i| "[tmp#{i}][sub#{i}] overlay=eof_action=pass:repeatlast=0 [tmp#{i + 1}];" }.join(' ')
  end

  def concat
    "[intro] [aintro] [tmp#{@subs.size}] [amain] [outro] [aoutro] concat=n=3:v=1:a=1"
  end

  def picture_filter(from, to)
    from = time_to_secons(from).round(1)
    len = (time_to_secons(to) - from).round(1)

    fadein = 'fade=t=in:st=0:d=0.2:alpha=1,'
    fadeout = "fade=t=out:st=#{(len - 0.2).round(1)}:d=0.2:alpha=1,"

    "#{input_video_filter},trim=duration=#{len},format=rgba,#{fadein}#{fadeout}setpts=PTS+#{from}/TB,fifo"
  end

  def time_to_secons(time)
    return time if time.is_a? Integer
    return time if time.is_a? Float
    return 100000000 if time == "" # time has not been set

    s = time.split(':').map {|v| v.to_f}

    return s[0] if s.size == 1
    return s[1] + s[0] * 60 if s.size == 2
    return s[2] + s[1] * 60 + s[0] * 60 * 60 if s.size == 3
    raise "time format not supported"
  end

  def input_video_filter
    @input_vide_filter ||= @params[:small] ? 'fps=30,scale=320:180,fifo'
                               : "fps=30,scale=#{main_video_resolution[:width]}:#{main_video_resolution[:height]},fifo"
  end

  def main_video_resolution
    @main_video_resolution ||= get_video_resolution_16x9 @video
  end
end
