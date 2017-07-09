module FileFormatUtils
  def get_video_resolution_16x9(path)
    r = get_resolution(path)
    i = (480.downto 1).find { |i| i*16 <= r[:width] && i*9 <= r[:height] }
    {width:i*16,height:i*9}
  end

  def get_crop_to_16x9_filter(path)
    r = get_video_resolution_16x9(path)
    "crop=#{r[:width]}:#{r[:height]}"
  end

  def get_resolution(path)
    res = `ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height,width '#{path}'`
    match = /streams_stream_0_width=(\d+)\nstreams_stream_0_height=(\d+)\n/.match(res)
    raise "ffprobe has unexpected output: '#{res}'" unless match
    width, height = match.captures
    {width:width.to_i, height:height.to_i}
  end
end
