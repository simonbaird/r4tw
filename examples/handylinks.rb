
$LOAD_PATH << '..'

require 'r4tw.rb'

TiddlyWiki.new.source_empty("http://www.tiddlywiki.com/").tiddlers_with_tag('systemServer').each do |p|
  #puts %{<li><a href="#{p.get_slice('URL')}">#{p.name}</a></li>}
  puts %(|[[#{p.name.sub(/Server$/,'')}]]\n|#{p.get_slice('URL')}\n|{{:#{p.name.sub(/Server$/,'')}}}\n|-\n)
end

