require 'digest/md5'
require 'oauth2'
require 'google_drive'

yetEncodedVideoDir = '/yet_encoded_video'
encodedVideoDir = '/encoded_video'
uploadDir = '1テレビ'

CLIENT_ID = ENV['CLIENT_ID']
CLIENT_SECRET = ENV['CLIENT_SECRET']
REFRESH_TOKEN = ENV['REFRESH_TOKEN']

# ファイル名とタイトルのマップつくる
fileAndTitleMaps = []
Dir.foreach(yetEncodedVideoDir) do |item|
  next if item == '.' or item == '..'

  if (item.match(/\.ts/))
    # タイトルを変換してファイル名生成
    file = Digest::MD5.new.update(item.sub(/\.ts/, '')).to_s + '.mp4'

    fileAndTitleMaps.push({'file' => file, 'title' => item.gsub(/\.ts/, '')})

  end
end

# 録画したビデオ(tsファイル)がなかったら終了
if (fileAndTitleMaps.empty?)
  'no recorded videos'
  exit(0)
end

# fileディレクトリ検索①
encodedVideos = []
Dir.foreach(encodedVideoDir) do |item|
  next if item == '.' or item == '..'

  if (item.match(/\.mp4\.lock$/))
    p 'now encoding'
    exit(0)
  end

  # エンコードしたファイルがあるか
  if (item.match(/\.mp4$/))
    encodedVideos.push(item)
  end
end

# エンコードしたビデオ(mp4ファイル)がなかったら終了
if (encodedVideos.empty?)
  p 'no encoded videos'
  exit(0)
end

# google drive上のディレクトリ検索②
client = OAuth2::Client.new(
    CLIENT_ID, CLIENT_SECRET,
    :site => "https://accounts.google.com",
    :token_url => "/o/oauth2/token",
    :authorize_url => "/o/oauth2/auth"
)

auth_token = OAuth2::AccessToken.from_hash(client, { :refresh_token => REFRESH_TOKEN, :expires_at => 3600 })
auth_token = auth_token.refresh!

session = GoogleDrive.login_with_oauth(auth_token.token)
uploadedFiles = []
for file in session.collection_by_title(uploadDir).files
  uploadedFiles.push(file.title.gsub(/\.mp4/, ''))
end


# ①のエンコード済み動画リストにあって②GDリストにないファイルがどれか探す
# 1 -> a,b,c
# encodedVideos
# 2 -> b,c
#
# output -> a
uploadMap = {}
for video in encodedVideos
  uploadTargetMap = nil
  for map in fileAndTitleMaps
    if (video === map['file'])
      uploadTargetMap = map
    end
  end

  searched = false
  for uploadedFile in uploadedFiles
    if (uploadedFile === uploadTargetMap['title'])
      searched = true
    end

    # アップロード候補が最後までアップロード済みファイル群になかったら未アップロード
    # アップロード対象にする
    if (searched === false && uploadedFiles.last === uploadedFile)
      uploadMap = uploadTargetMap
    end
  end

end

# アップロード対象がなかったら終了
if (uploadMap.empty?)
  'no upload target videos'
  exit(0)
end

p 'uploading ' + uploadMap['title'] + '.mp4 ...'
folder = session.file_by_title(uploadDir)
folder.upload_from_file(encodedVideoDir + '/' + uploadMap['file'], uploadMap['title'] + '.mp4', :convert => false)
