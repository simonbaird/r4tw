
require 'r4tw.rb'
puts make_tw { source_url "http://www.tiddlywiki.com/" }.get_tiddler("HelloThere").modifier
