
class GoogleWorkdir
  attr_reader :workdir

  def initialize(google_dir)
    @workdir = google_dir
  end

  def info
    @info ||= workdir.spreadsheets.find {|s| s.title == "info"} or raise 'can not find info.gsheet!'
  end

  def upload(path, name)
    f = workdir.file_by_title(name)
    f&.delete true
    workdir.upload_from_file path, name, convert:false
  end

  def upload_directory(path, name)
    collection = workdir.subcollection_by_title name
    if collection == nil || collection.id == nil
      collection = workdir.create_subcollection name
    end

    collection.files.each {|f| f.delete}

    Dir.entries(path)
        .map {|f| File.join(path, f) }
        .select {|f| !File.directory? f }
        .each {|f| collection.upload_from_file f, nil, :convert => false }
  end

  def download(name, path)
    File.delete(path) if File.exist?(path)
    f = workdir.file_by_title(name) or raise "file #{name} not found at '#{workdir.title}'!"
    f.download_to_file(path)
  end

  def presentation_url
    presentation_dir = workdir.file_by_title 'presentation'
    files = presentation_dir.files
    raise 'presentation directory must have exactly 1 file or directory to share' unless files.size == 2
    to_share = files.find {|x| x.title != 'pages'}
    to_share.acl.push({type: 'anyone', role: 'reader'})
    to_share.human_url
  end
end
