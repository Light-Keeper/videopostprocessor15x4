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
