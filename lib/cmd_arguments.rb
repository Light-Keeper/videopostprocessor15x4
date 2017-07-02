require 'optparse'

class CmdArgumens
  attr_reader :options

  def initialize()
    @options = {}
    OptionParser.new do |opts|
      opts.banner = "Usage: process.rb [options]"
      opts.on('-t', '--trello=URI', 'get info frim trello') { |p| @options[:trello] = p }
      opts.on('-w', '--workdir=ID', 'google directoty id') { |p| @options[:workdir] = p }
      opts.on('-i', '--input=URI', 'URI of video') { |p| @options[:input] = p }
      opts.on('-p', '--pic', 'rebuild all pictutes') { || @options[:pic] = true }
      opts.on('-v', '--video', 'rebuild video') { |p| @options[:video] = true }
      opts.on('-d', '--dry', 'dont actually run conversion') { |p| @options[:dry] = true }
      opts.on('-s', '--small', 'generate small video') { |p| @options[:small] = true }
    end.parse!
  end

end

