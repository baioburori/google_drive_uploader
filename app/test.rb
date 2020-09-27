p 'start md5'
require 'digest/md5'
p Digest::MD5.new.update('test').to_s
p 'end md5'
