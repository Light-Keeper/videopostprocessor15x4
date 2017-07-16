require "open-uri"
require 'trello'
require 'json'

Trello.configure do |config|
  cred = JSON.parse File.read("./secret/trello.json")
  config.developer_public_key = cred['key'] # The "key" from step 1
  config.member_token = cred['token'] # The token from step 2.
end

class TrelloAccessor

  attr_reader :id, :client

  def initialize(id)
    @client = Trello.client
    match = id.match(/https:\/\/trello.com\/c\/([^\/?]*).*/)
    id = match.captures[0] if match
    @id = id
  end

  def video() extract_url(comments[0]) end
  def workdir() extract_url(comments[-1]) end

  def preview
    attachment = card.attachments.find {|a| a.name.downcase =~ /^.*?(\.png$|\.jpg$)/}
    return nil unless attachment

    name = './out/background.png'
    File.open(name, 'wb') do |fo|
      fo.write open(attachment.url).read
    end
    name
  end

  def listname
    card.list.name
  end

  def set_label(name)
    return if card.labels.any? {|l| l.name == name }
    label = card.board.labels.find {|l| l.name == name}
    card.add_label label if label
  end

  private

  def card
    @card ||= client.find(:card, id)
  end

  def comments
    @comments ||= card.comments.map {|c| c.text }
  end

  def extract_url(text)
    URI.extract(text)[0]
  end
end
