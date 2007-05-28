
$LOAD_PATH << '..'

require 'r4tw.rb'

url = "http://www.tiddlywiki.com/" 
TiddlyWiki.new.empty_source(url).tiddlers_with_tag('contentPublisher').each do |p|
  puts %{<li><a href="#{p.get_slice('URL')}">#{p.name}</a></li>}
end

