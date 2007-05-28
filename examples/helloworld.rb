
$LOAD_PATH << '..'

require 'r4tw'

make_tw {

  source_file '../tests/empties/2.1.3.html'

  add_tiddler_from_scratch({
    'tiddler'=>'SiteTitle',
    'text'=>'Hello from r4tw',
    'modifier'=>'r4tw',
  })

  add_tiddler_from_file 'hello.js'

  to_file 'mytw.html'

}
