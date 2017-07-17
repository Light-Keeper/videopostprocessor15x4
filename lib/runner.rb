require_relative 'trello_accessor'
require_relative 'google/google_factoty'
require_relative 'lection/general_info'
require_relative 'lection/publicator'
require_relative 'picture_generator'

def action_update_pictures(trello, workdir, info)
  puts 'rendering subtitles....'
  pic = PictureGenerator.new('./out/pic')
  pic.clear
  pic.render_title info.lector_name, info.title
  pic.render_subs info.subs
  puts 'uploading subtitles....'
  workdir.upload_directory('./out/pic', 'generated_images')
end

def action_publish(trello, workdir, info)
  puts 'generating youtube text....'
  publicator = Publicator.new(workdir, GoogleFactory.shortnter)
  publicator.generate_youtube_text

  preview = trello.preview
  if preview
    puts "downloaded preview to #{preview}"
    publicator.update_background(preview)
    puts 'preview updated'
  else
    puts 'trello does not have preview attached!'
  end
end

def action_default(trello, workdir, info)
  list = trello.listname
  puts "the card is in list '#{list}'"

  if list == 'подготовка к публикации'
    return action_publish trello, workdir, info
  end

  if list == 'проверить и сконвертировать субтитры'
    return action_update_pictures trello, workdir, info
  end

  puts 'don\'t know what to do with cards in this list!'
end

def run_with_lection
  raise 'must have exactly 1 argument - trello link' unless ARGV.one?

  trello_url = ARGV.first
  puts "using trello link: #{trello_url}"
  trello = TrelloAccessor.new(trello_url)

  workdir_url = trello.workdir
  puts "workdir url: #{workdir_url}"

  workdir = GoogleFactory.workdir(workdir_url)
  info = GeneralInfo.new(workdir)
  puts "it's the lection '#{info.title} - #{info.lector_name}'"

  yield trello, workdir, info

  # trello.set_label 'automatic step done'
  puts 'done.'
end
