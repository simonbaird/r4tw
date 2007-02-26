
require 'test/unit'
$LOAD_PATH << ".."; require 'r4tw'


class MyTest < Test::Unit::TestCase

  def test_tiddler
    
    t = Tiddler.new.from_scratch
                     
    assert_match(
      /<div tiddler="New Tiddler" modifier="r4tw" modified="\d+" created="\d+" tags=""><\/div>/,
      t.to_div
      )
           
    assert_equal("New Tiddler",t.name)
    
    assert_equal("r4tw",t.modifier)   
        
    assert_equal(
      t.to_div,
      Tiddler.new.from_div(t.to_div).to_div  
      )
        
    t.fields['foo'] = "blah"
    assert_equal(t.foo,"blah")        

    assert_match(
      /<div tiddler="New Tiddler" modifier="r4tw" modified="\d+" created="\d+" tags="" foo="blah"><\/div>/,
      t.to_div
      )
           
    t.add_tag("MyTag")    
    assert_match(
      /<div tiddler="New Tiddler" modifier="r4tw" modified="\d+" created="\d+" tags="MyTag" foo="blah"><\/div>/,
      t.to_div
      )

    t.add_tag("My Other Tag")
    assert_match(
      /<div tiddler="New Tiddler" modifier="r4tw" modified="\d+" created="\d+" tags="MyTag \[\[My Other Tag\]\]" foo="blah"><\/div>/,
      t.to_div
      )

    t.remove_tag("MyTag")
    assert_match(
      /<div tiddler="New Tiddler" modifier="r4tw" modified="\d+" created="\d+" tags="\[\[My Other Tag\]\]" foo="blah"><\/div>/,
      t.to_div
      )
           
        
  end  
end
