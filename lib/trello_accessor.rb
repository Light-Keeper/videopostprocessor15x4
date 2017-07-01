require 'trello'
require 'json'

Trello.configure do |config|
  cred = JSON.parse File.read("./secret/trello.json")
  config.developer_public_key = cred['key'] # The "key" from step 1
  config.member_token = cred['token'] # The token from step 2.
end

class TrelloAccessor

  def initialize()
    @client = Trello.client
  end

  def card_info(id)
    match = id.match(/https:\/\/trello.com\/c\/([^\/?]*).*/)
    id = match.captures[0] if match
    card = @client.find(:card, id)
    comments = card.comments.map {|c| c.text }
    {
        :workdir => extract_url(comments[-1]),
        :video => extract_url(comments[0])
    }
  end

  def extract_url(text)
    URI.extract(text)[0]
  end

end