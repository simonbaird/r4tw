
require 'test/unit'

$LOAD_PATH << ".."; require 'r4tw'

class TiddlerTest < Test::Unit::TestCase

  def test_tiddler
    
    t = Tiddler.new.from_scratch
                     
    assert_match(
      /<div tiddler="New Tiddler" modifier="YourName" modified="\d+" created="\d+" tags=""><\/div>/,
      t.to_div
      )
           
    assert_equal("New Tiddler",t.name)
    assert_equal("YourName",t.fields['modifier'])   
        
    assert_equal(
      t.to_div,
      Tiddler.new.from_div(t.to_div).to_div  
      )
        
    assert_equal(0,t.extra_fields.length)        
        
    t.fields[:foo] = "blah"
    assert_equal([:foo],t.extra_fields)        

    assert_match(
      /<div tiddler="New Tiddler" modifier="YourName" modified="\d+" created="\d+" tags="" foo="blah"><\/div>/,
      t.to_div
      )
           
    t.add_tag("MyTag")    
    assert_match(
      /<div tiddler="New Tiddler" modifier="YourName" modified="\d+" created="\d+" tags="MyTag" foo="blah"><\/div>/,
      t.to_div
      )

    t.add_tag("My Other Tag")
    assert_match(
      /<div tiddler="New Tiddler" modifier="YourName" modified="\d+" created="\d+" tags="MyTag \[\[My Other Tag\]\]" foo="blah"><\/div>/,
      t.to_div
      )

    t.remove_tag("MyTag")
    assert_match(
      /<div tiddler="New Tiddler" modifier="YourName" modified="\d+" created="\d+" tags="\[\[My Other Tag\]\]" foo="blah"><\/div>/,
      t.to_div
      )
           
        
  end  
end
