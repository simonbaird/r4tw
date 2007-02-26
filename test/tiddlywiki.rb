
require 'test/unit'

$LOAD_PATH << ".."; require 'r4tw'

class TiddlerTest < Test::Unit::TestCase

  def setup
    @tw = make_tw {
      source_file "empty.html"
    }
    @tw2 = make_tw {
      source_file "empty2.html"
    }
  end

  def test_load_empty
                 
    assert_equal(
      @tw.to_s,
      File.read("empty.html")
      )

    assert_equal(
      @tw2.to_s,
      File.read("empty2.html")
      )

  end
    
  def test_orig_tiddler
                 
    assert_equal(
      @tw2.get_tiddler("translations").name,
      "translations"
      )
            
    assert_equal(
      @tw.tiddlers.length,
      0)            

    assert_equal(
      @tw2.tiddlers.length,
      1)            
       
  end   
  
end
