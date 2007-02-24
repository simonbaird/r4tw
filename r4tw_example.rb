
# until I make a better example..
# this is how I manage http://mptw.tiddlyspot.com/empty.html

require 'r4tw'

make_tw {
  source_file           'empty.html'
  add_tiddlers_from_dir 'core'
  package_as_from_dir   'misc/MptwLayoutPlugin.js', 'layout'
  store_to_file         'upload/upgrade.html'
  add_tiddlers_from_dir 'noupgrade'
  to_file               'upload/empty.html'
  store_to_divs         'upload/MonkeyPirateTiddlyWiki.tiddler' # tiddlyspot uses this
}
