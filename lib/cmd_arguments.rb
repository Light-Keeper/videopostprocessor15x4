require 'optparse'

class CmdArgumens
  attr_reader :options

  def initialize()
    @options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: process.rb [options]"
      opts.on('-t', '--trello=URI', 'get info frim trello') { |p| @options[:trello] = p }
      opts.on('-w', '--workdir=ID', 'google directoty id') { |p| @options[:workdir] = p }
      opts.on('-v', '--video=URI', 'URI of video') { |p| @options[:video] = p }
      opts.on('-p', '--pic', 'rebuild all pictutes') { || @options[:pic] = true }
      opts.on('-c', '--convert', 'rebuild video') { |p| @options[:convert] = true }
      opts.on('-d', '--dry', 'dont actually run conversion') { |p| @options[:dry] = true }
      opts.on('-s', '--small', 'generate small video') { |p| @options[:small] = true }
      opts.on('-o', '--output=PATH', 'output video') { |p| @options[:output] = p }
    end.parse!
  end

end

