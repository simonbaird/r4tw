
require 'test/unit'

$LOAD_PATH << ".."; require 'r4tw'

class TagTest < Test::Unit::TestCase

  def setup
    @tw = make_tw {
      source_file "empty.html"
      add_tiddler Tiddler.new.from_scratch({'tiddler'=>'foo'},'bar').add_tag("hey")
    }
  end

  def test_tag
      assert_match(
        /<div tiddler="foo".*tags="hey">/,
	@tw.to_s
	)

      @tw.get_tiddler("foo").add_tag("now")
      assert_match(
        /<div tiddler="foo".*tags="hey now">/,
	@tw.to_s
	)

      #@tw.to_file "testout.html"
  end

end
