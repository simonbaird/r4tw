
require 'test/unit'

$LOAD_PATH << ".."
require 'r4tw'

class CreateFromTest < Test::Unit::TestCase


  def test_stuff
      
    ## just checking the the case statement
    ## in Tiddler#from works as it should

    foo = { 'text' => 'foo','tiddler' => 'blah' }
    assert_equal(
      Tiddler.new.from(foo).to_div,
      Tiddler.new.from_scratch(foo).to_div
    )
    
    fff = 'http://www.tiddlywiki.com/#HelloThere'
    assert_equal(
      Tiddler.new.from(fff).to_div,
      Tiddler.new.from_remote_tw(fff).to_div
    )

    ggg = 'http://simonbaird.com/r4tw/'
    assert_equal(
      Tiddler.new.from(ggg,foo).to_div,
      Tiddler.new.from_url(ggg,foo).to_div
    )
    
    hhh = "#{this_dir(__FILE__)}/withcontent/22b5index.html#HelloThere"
    assert_equal(
      Tiddler.new.from(hhh).to_div,
      Tiddler.new.from_local_tw(hhh).to_div
    )

    iii = "#{this_dir(__FILE__)}/withcontent/nothing.js"
    assert_equal(
      Tiddler.new.from(iii).to_div,
      Tiddler.new.from_file(iii).to_div
    )

    # since it's a js file
    assert_equal(
      "systemConfig",
      Tiddler.new.from(iii).tags
    )
   
    ## now test the add_tiddler_from a little bit
    @tw = make_tw { source_file "#{this_dir(__FILE__)}/empties/2.2.0.beta5.html" }
    @tw.add_tiddlers_from([foo,fff,ggg,hhh,iii])
    # 4 is right because two of them are called blah and the 2nd one overwrites the first :)
    assert_equal(4,@tw.tiddlers.length) 
    
    

    
  end

end