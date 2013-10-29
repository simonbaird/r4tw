
require 'r4tw'

def get_rev
  `svnversion .`.split(':').last
end

make_tw {

  # actually this is an mptw empty file not a bare one
  source_file            'empty.html'

  remove_tiddler         "MptwUpgradeTsURL"
  remove_tiddler         "MptwUpgradeURL"
  remove_tiddler         "MonkeyPirateTiddlyWiki"

  add_tiddlers_from_dir  "core"

  get_tiddler('MonkeyGTDVersion').text.sub!(/\$timestamp\$/,get_rev)

  add_tiddlers_from_file "misc/Components.divs"

  package_as_from_dir    "misc/Dashboards.js", "dashes"
  package_as_from_dir    "misc/Panels.js", "panels"
  add_tiddlers_from_dir  "lists"

  package_as_from_dir    "misc/MonkeyGTDLists.js", "lists"

  store_to_file          "upload/upgrade.html"

  add_tiddlers_from_dir  "noupgrade"
  add_tiddlers_from_file "misc/Components2.divs"

  to_file                "upload/empty.html"

  add_tiddlers_from_file "misc/Demo.divs"
  get_tiddler("Dashboard").text = "See http://monkeygtd.tiddlyspot.com and http://monkeygtd.blogspot.com for more info. To download right click [[empty.html|empty.html]] and 'Save as...'"
  to_file                "upload/index.html"
}
