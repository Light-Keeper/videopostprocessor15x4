require 'nokogiri'
require_relative './google_accessor'

class MediaSync

  def initialize(url)
    @url = url
    @google = GoogleAccessor.new
  end

  def sync_from_default_soruce
    media.subcollections.each do |mediasource|
      array = descriptor[:paddings][mediasource.title] or raise "data for #{mediasource.title} is not found!"
      mediasource.file_by_title('pluraleyes_synctemp')&.delete
      array.each do |data|
        mediasource.file_by_title(data[:padding_name])&.delete
        next if data[:gap] == 0

        file = generate_padding_file(descriptor[:fps], data[:gap], data[:padding_name])
        mediasource.upload_from_file(file, data[:padding_name])
      end
    end

    p descriptor
  end

  private

  def generate_padding_file(fps, frames, name)
    FileUtils.mkpath './out/tmp'

    cmd = "ffmpeg -f lavfi -i testsrc -vf 'fps=#{fps},trim=start_frame=0:end_frame=#{frames},crop=320:180' -pix_fmt yuv420p -y ./out/tmp/#{name}"
    p cmd
    system cmd

    "./out/tmp/#{name}"
  end

  def workdir
    @workdir ||=  @google.file_by_url(@url)
  end

  def media
    @media ||= workdir.subcollection_by_title('media') or raise 'media folder not found in ' + @url
  end

  def descriptor
    return @descriptor if @descriptor
    projects = workdir.subcollection_by_title('projects') or raise 'projects folder not found in ' + @url
    sync_xml_file = projects.file_by_title('sync.xml') or raise 'projects/sync.xml file is not found'
    descriptor = parse_fcp_xml sync_xml_file.download_to_string
    @descriptor = descriptor
  end

  def parse_fcp_xml(xml_string)
    doc = Nokogiri::XML(xml_string)
    fps = doc.at_xpath('//sequence/rate/timebase')&.content.to_i or raise 'can not find frame rate for sequence!'

    files = doc.xpath('//sequence/media/*[self::video or self::audio]/track/clipitem').map do |item|
      startframe = item.at_xpath('./start')&.content.to_i or raise 'can not find start at ' + item.inspect
      endframe = item.at_xpath('./end')&.content.to_i or raise 'can not find end at ' + item.inspect
      file =  item.at_xpath('./file/pathurl')&.content or raise 'can not find pathurl at ' + item.inspect
      souce,name = file.split('/').slice(-2, 2)
      {startframe:startframe, endframe:endframe, souce:souce, name:name}
    end

    paddings = files
                   .uniq
                   .group_by {|f| f[:souce]}
                   .each do |key, array|
      array
          .sort_by {|file| file[:name]}
          .inject(0) do |time, file|

        file[:gap] = file[:startframe] - time
        name_split = file[:name].split('.')
        name = name_split[0]
        ext = name_split[-1]
        file[:padding_name] = "#{name}-padding.#{ext}"

        _next = file[:endframe]
        file.delete :endframe
        file.delete :startframe
        file.delete :souce
        file.delete :name
        _next
      end
    end
    {fps:fps, paddings:paddings}
  end
end


media_sync = MediaSync.new('https://drive.google.com/drive/folders/0B4etbxqo9tumVmQwMHdwT3BUZms')
media_sync.sync_from_default_soruce

