
require 'test/unit'

require '../r4tw.rb'

class TiddlerTest < Test::Unit::TestCase

  def setup
    @tw  = make_tw { source_file "withcontent/empty.html" }
    @tw2 = make_tw { source_file "withcontent/empty2.html" }
    @tw3 = make_tw { source_file "empties/2.2.0.beta5.html" }
    @tw4 = make_tw { source_file "withcontent/2.2.0.beta5.html" }

    #puts @tw4.tiddlers[0].name
  end

  def test_load_empty
    
    # I had to manually remove the ctrl-M to make these tests work... 
    assert_equal(@tw.to_s,  File.read("withcontent/empty.html"))
    assert_equal(@tw2.to_s, File.read("withcontent/empty2.html"))
    assert_equal(@tw3.to_s, File.read("empties/2.2.0.beta5.html"))
    assert_equal(@tw4.to_s, File.read("withcontent/2.2.0.beta5.html"))

  end
    
  def ztest_orig_tiddler
                 
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
