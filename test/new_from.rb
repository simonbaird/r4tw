
require 'test/unit'

$LOAD_PATH << ".."; require 'r4tw'

class NewFromScr < Test::Unit::TestCase


  def test_1
    assert_equal(
      Tiddler.new.from_scratch({'tiddler'=>'foo'},'bar').to_div,
      Tiddler.new_from_scratch({'tiddler'=>'foo'},'bar').to_div
    )
  end

  def test_2
    foo = make_tw{source_file}
    foo.zadd_tiddler_from_scratch({'tiddler'=>'foo'},'bar')
    assert_equal(
      Tiddler.new_from_scratch({'tiddler'=>'foo'},'bar').to_div,
      foo.get_tiddler('foo').to_div
      )
  end

end
