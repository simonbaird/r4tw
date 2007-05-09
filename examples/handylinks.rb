
$LOAD_PATH << '..'

require 'r4tw.rb'

puts "<ul>"
make_tw { source_url "http://www.tiddlywiki.com/" }.tiddlers_with_tag('contentPublisher').each do |p|
  puts %{<li><a href="#{p.get_slice('URL')}">#{p.name}</a></li>}
end
puts "</ul>"

