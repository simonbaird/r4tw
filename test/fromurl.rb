
require 'test/unit'

$LOAD_PATH << ".."; require 'r4tw'

class FromUrl < Test::Unit::TestCase

  include Utils

  def setup
  ### fetch_url("http://www.tiddlywiki.com/empty.html").eat_ctrl_m!.to_file("empty.html")
    @tw = make_tw {
      source_url
    }
  end

  def test_it
    assert_equal(
	  @tw.raw,
	  fetch_url("http://www.tiddlywiki.com/empty.html").eat_ctrl_m!
	)
  end

end
