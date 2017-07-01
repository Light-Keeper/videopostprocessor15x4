require 'optparse'

class CmdArgumens
  attr_reader :options

  def initialize()
    @options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: process.rb [options]"
      opts.on('-p', '--pic', 'rebuild all pictutes') { || @options[:pic] = true }
      opts.on('-w', '--workdir=ID', 'google directoty id') { |p| @options[:workdir] = p }
      opts.on('-v', '--video=URI', 'URI of video') { |p| @options[:video] = p }
      opts.on('-d', '--dry', 'ffmpeg dry run') { |p| @options[:dry] = true }
      opts.on('-s', '--small', 'generate small video') { |p| @options[:small] = true }
      opts.on('-t', '--trello=URI', 'get info frim trello') { |p| @options[:trello] = p }
    end.parse!
  end

end

