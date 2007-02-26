
require 'test/unit'

$LOAD_PATH << ".."; require 'r4tw'

class ShadowTest < Test::Unit::TestCase

  def setup
    @tw = make_tw {
      source_file "empty.html"
    }
  end

  def test_shadow
      @tw.add_shadow_tiddler Tiddler.new.from_scratch({'tiddler'=>'foo','text'=>'bar'})
      #@tw.to_file "shadowtest.html"
      assert_match(
      	/^config.shadowTiddlers\["foo"\] = "bar";/m,
	@tw.to_s
	)
  end

end
