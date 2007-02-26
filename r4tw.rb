#
# =r4tw
# Author:: Simon Baird
# r4tw is some ruby classes for manipuating TiddlyWikis and tiddlers.
# It is similar to cook and ginsu but much cooler.
#
# <i>$rev: 1684 $</i>

require 'pathname'
require 'open-uri'


module Utils #:nodoc:

  def read_file(file_name)
    File.read(file_name)
  end

  def fetch_url(url)
    open(url).read.to_s
  end

  def read_from(file_or_url)
    if file_or_url =~ /^(ftp|http|https):\/\//
      fetch_url(file_or_url)
    else
      read_file(file_or_url)
    end
  end

  def this_dir
    Pathname.new($0).expand_path.dirname
  end

end

class String #:nodoc:
  def to_file(file_name)
    File.open(file_name,"w") { |f| f << to_s }
  end
end

#
#-- TiddlyWiki related utils
#

class String #:nodoc:
 
  def escapeLineBreaks
    gsub(/\\/m,"\\s").gsub(/\n/m,"\\n").gsub(/\r/m,"")
  end
  
  def unescapeLineBreaks
    # not sure what \b is for
    gsub(/\\n/m,"\n").gsub(/\\b/m," ").gsub(/\\s/,"\\").gsub(/\r/m,"")
  end
  
  def encodeHTML
    gsub(/&/m,"&amp;").gsub(/</m,"&lt;").gsub(/>/m,"&gt;").gsub(/\"/m,"&quot;")
  end
  
  def decodeHTML
    gsub(/&amp;/m,"&").gsub(/&lt;/m,"<").gsub(/&gt;/m,">").gsub(/&quot;/m,"\"")
  end

  def readBracketedList
    scan(/\[\[([^\]]+)\]\]|(\S+)/).map {|m| m[0]||m[1]}
  end  

  # From some reason the empty.html file at tiddlywiki.com
  # sometimes gets a few spurious Ctrl-M chars in it
  # This method can be used to eat them
  def eat_ctrl_m!
    gsub!("\x0d",'')
  end

  def as_tag_field
    self
  end

end

class Array #:nodoc:
  def toBracketedList
    map{ |i| (i =~ /\s/) ? ("[["+i+"]]") : i }.join(" ")
  end    

  def as_tag_field
    toBracketedList
  end

end

class Time #:nodoc:
  def convertToLocalYYYYMMDDHHMM()
    self.localtime.strftime("%Y%m%d%H%M")    
  end
    
  def convertToYYYYMMDDHHMM()
    self.utc.strftime("%Y%m%d%H%M")    
  end
    
  def Time.convertFromYYYYMMDDHHMM(d)
    m = d.match(/(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/)
    Time.utc(m[1],m[2],m[3],m[4],m[5])        
  end
    
end


#
# =Tiddler
# For creating and manipulating tiddlers

class Tiddler

  include Utils 

  @@main_fields = %w[tiddler modifier modified created tags]

  # text is not really a field in TiddlyWiki it makes
  # things easier to make it one here.  It could possibly
  # clash with a real field called text.  This might be a
  # serious problem but I will ignore it for now...

  @@defaults = {
      'tiddler'  => 'New Tiddler',
      'modified' => Time.now.convertToYYYYMMDDHHMM,
      'created'  => Time.now.convertToYYYYMMDDHHMM,
      'modifier' => 'r4tw',
      'tags'     => '',
      'text'    => '', 
  }
  
  # New by itself doesn't do much so instead you usually use one of these:
  # * Tiddler.new.from_scratch
  # * Tiddler.new.from_div
  # * Tiddler.new.from_file
  # * Tiddler.new.from_url
  # * Tiddler.new.from_remote_tw
  #
  def initialize
        @fields = @@defaults
        @text = ""
  end

  # Creates a tiddler from scratch. 
  # Fields containing
  # Example:
  #  t = Tiddler.new({
  #    'tiddler'=>'HelloThere',
  #    'text'=>'And welcome',
  #  })
  # Other built-in fields are +modified+, +created+, +modifier+ and +tags+. Any other
  # fields you add will be created as tiddler extended fields.
  #
  def from_scratch(fields={})
    @fields = @@defaults.merge(fields)
    @fields['tags'] &&= @fields['tags'].as_tag_field # in case it's an array
    self
  end

  # Creates a tiddler from a string containg an html div such as
  # would be found in a TiddlyWiki storeArea
  #
  def from_div(div)
    match_data = div.match(/<div([^>]+)>([^<]*)<\/div>/)
    field_string = match_data[1]
    text_string = match_data[2]

    field_string.scan(/ ([\w\.]+)="([^"]+)"/) do |name,value|
      @fields[name] = value
    end

    @fields['text'] = text_string.unescapeLineBreaks.decodeHTML

    self
  end

  def from_remote_tw(url)
    tiddler_name = url.split("#").last
    # XXX fix me soon
    make_tw { source_empty(url) }.get_tiddler(tiddler_name)
  end

  def from_url(url,fields={})
    @text = fetch_url(url)
    @fields = @@defaults.merge(fields)    
    self
  end

  def from_file(file_name,fields={})
    @text = read_file(file_name)
    @fields = @@defaults.merge(fields)
    
    ext = File.extname(file_name)
    @fields['tiddler'] = File.basename(file_name,ext)
    @fields['modified'] = File.mtime(file_name).convertToYYYYMMDDHHMM
    
    case ext
    
      when ".js"
        add_tag "systemConfig"
        
      # these should be more configurable probably
      when ".html"
        add_tag "html"
      when ".css"
        add_tag "css"                
      when ".pub"
        add_tag "contentPublisher"                
      when ".palette"
        add_tag "palette"                
        
    end
    
    self
  end

  def to_div
    main_fields = @@main_fields
    extended_fields = @fields.keys.reject{ |f| @@main_fields.include?(f) || f == 'text' }.sort

    fields_string =
      main_fields.map { |f| %{#{f}="#{@fields[f]}"} } +
      extended_fields.map{ |f| %{#{f}="#{@fields[f]}"} }    

    "<div #{fields_string.join(' ')}>#{@fields['text'].escapeLineBreaks.encodeHTML}</div>"
  end

  def to_s
    to_div
  end

  def method_missing(method,*args)

    method = method.to_s

    synonyms = {
      'name'    => 'tiddler',
      'title'   => 'tiddler',
      'content' => 'text',
      'body'    => 'text',
    }

    method = synonyms[method] || method

    if @@main_fields.include? method or @fields[method]
      @fields[method]
    else
      raise "No such tiddler field or method #{method}"
    end

  end

  #------------------------------------------------------------

  def append(text)
    @fields['text'] += text
    self
  end

  def rename(new_name)
    @fields['tiddler'] = new_name
    self
  end

  def copy
    Tiddler.new.from_div(self.to_div)
  end

  def copy_to(new_title)
    copy.rename(new_title)
  end
  
  def add_tag(new_tag)
    fields['tags'] = fields['tags'].
      readBracketedList.
        push(new_tag).
          uniq.
            toBracketedList

    self
  end

  def remove_tag(old_tag)
    fields['tags'] = fields['tags'].
      readBracketedList.
        reject { |tag| tag == old_tag }.
          toBracketedList

    self
  end

  def has_tag(tag) 
    fields['tags'] && fields['tags'].readBracketedList.include?(tag)
  end

  def get_slices
    if not @slices
      @slices = {}
      slice_re = /(?:[\'\/]*~?(\w+)[\'\/]*\:[\'\/]*\s*(.*?)\s*$)|(?:\|[\'\/]*~?(\w+)\:?[\'\/]*\|\s*(.*?)\s*\|)/m
      text.scan(slice_re).each do |l1,v1,l2,v2|
        @slices[l1||l2] = v1||v2;
      end
    end
    @slices
  end

  def get_slice(slice)
    get_slices[slice]
  end

  # Experimental
  #
  def plugin_meta(slice=nil)
    # see http://www.tiddlywiki.com/#ExamplePlugin
    if not @plugin_meta
      meta = %w[Name Description Version Date Source Author License CoreVersion Browser]
      @plugin_meta = get_slices.reject{|k,v| not meta.include?(k)}
    end
    if slice
      @plugin_meta[slice]
    else
      @plugin_meta
    end
  end

end


#
# Tiddlywiki
# 

class TiddlyWiki

  include Utils 

  attr_accessor :orig_tiddlers, :tiddlers, :raw

  def initialize(&block)
  
    @tiddlers = []
    if block
      instance_eval(&block)
    end
  end

  # this should replace all the add_tiddler_from_blah methods
  def method_missing(method_name,*args);
    case method_name.to_s
    when /^add_tiddler_(.*)$/
      add_tiddler(Tiddler.send("new_#{$1}",*args))
    end
  end

  def source_empty(empty_file)
    @empty_file = empty_file
    if empty_file =~ /^https?/
      @raw = fetch_url(@empty_file)
    else
      @raw = read_file(@empty_file)
    end
    @raw.eat_ctrl_m!
    @core_hacks = []
    @orig_tiddlers = get_orig_tiddlers
    @tiddlers = @orig_tiddlers
  end

  def source_file(file_name="empty.html") 
    source_empty(file_name)
  end

  def source_url(url="http://www.tiddlywiki.com/empty.html")
    source_empty(url)
  end

  @@store_regexp = /^(.*<div id="storeArea">\n?)(.*)(\n?<\/div>\n<!--POST-BODY-START-->.*)$/m

  def pre_store
    @raw.sub(@@store_regexp,'\1')
  end

  def store
    @raw.sub(@@store_regexp,'\2')
  end

  def post_store
    @raw.sub(@@store_regexp,'\3')
  end

  def tiddler_divs
    store.strip.to_a
  end

  def add_core_hack(regexp,replace)
    # this is always a bad idea... ;)
    @core_hacks.push([regexp,replace])
  end

  def get_orig_tiddlers
    tiddler_divs.inject([]) do |tiddlers,tiddler_div|
      tiddlers << Tiddler.new.from_div(tiddler_div)
    end
  end

  def tiddler_titles
    @tiddlers.map { |t| t.name }
  end

  def tiddlers_with_tag(tag)
    @tiddlers.select{|t| t.has_tag(tag)}
  end

  def add_tiddler(tiddler)
    remove_tiddler(tiddler.name)
    @tiddlers << tiddler
    tiddler
  end

  def remove_tiddler(tiddler_name)
    @tiddlers.reject!{|t| t.name == tiddler_name}
  end
  
  def add_tiddler_from_url(url,fields)
    add_tiddler Tiddler.new.from_url(url,fields)
  end

  def add_tiddler_from_remote_tw(url)
    add_tiddler Tiddler.new.from_remote_tw(url)
  end


  def add_tiddler_from_file(file_name)
    add_tiddler Tiddler.new.from_file("#{file_name}")
  end

  def add_shadow_tiddler(tiddler)
    # shadow tiddlers currently implemented as core_hacks
    add_core_hack(
      /^\/\/ End of scripts\n/m,
      "\\0\nconfig.shadowTiddlers[\"#{tiddler.name}\"] = #{tiddler.text.dump};\n\n"
    )
  end
  
  def add_shadow_tiddler_from_file(file_name)
    add_shadow_tiddler Tiddler.new.from_file("#{file_name}")
  end

  def add_tiddlers(file_names)
    file_names.reject{|f| f.match(/^#/)}.each do |f|
      add_tiddler_from_file(f)
    end
  end

  def add_tiddlers_from_dir(dir_name)
    add_tiddlers(Dir.glob("#{dir_name}/*"))
  end

  def add_shadow_tiddlers_from_dir(dir_name)
    Dir.glob("#{dir_name}/*").each do |f|
      add_shadow_tiddler_from_file(f)
    end
  end

  def package_as_from_dir(file_name,dir_name)
    package_as(file_name,Dir.glob("#{dir_name}/*"))
  end

  def add_tiddlers_from_file(file_name)
    # a file full of divs
    File.read(file_name).to_a.inject([]) do |tiddlers,tiddler_div|
      @tiddlers << Tiddler.new.from_div(tiddler_div)
    end
  end

  def get_tiddler(tiddler_title)
    @tiddlers.select{|t| t.name == tiddler_title}.first
  end

  def to_s
    pre = pre_store
    @core_hacks.each do |hack|
      pre.gsub!(hack[0],hack[1])
    end
    "#{pre}#{store_to_s}#{post_store}"
  end

  def store_to_s
    @tiddlers.sort_by{|t| t.name}.inject(""){ |out,t|out << t.to_div << "\n"}
  end

  def store_to_file(file_name)
    # xmp is for human readability. probably should remove it
    File.open(file_name,"w") { |f| f << "<xmp><div id=\"storeArea\">\n#{store_to_s}</div></xmp>" }
    puts "Wrote store only to '#{file_name}'"
  end

  def store_to_divs(file_name)
    File.open(file_name,"w") { |f| f << store_to_s }
    puts "Wrote tiddlers only to '#{file_name}'"
  end

  def to_file(file_name)
    File.open(file_name,"w") { |f| f << to_s }
    puts "Wrote tw file to '#{file_name}'"
  end

  def package_as(file_name,package_file_names)
    new_tiddler = add_tiddler Tiddler.new.from_file(file_name)
    new_tiddler.append_content(package(package_file_names))
    # date of the most recently modified
    new_tiddler.fields['modified'] = package_file_names.push(file_name).map{|f| File.mtime(f)}.max.convertToYYYYMMDDHHMM
  end
  
  def package(file_names)
    "//{{{\nmerge(config.shadowTiddlers,{\n\n"+
    ((file_names.map do |f|
      Tiddler.new.from_file(f)
    end).map do |t|
      "'" + t.name + "':[\n " + 
          t.text.dump.gsub(/\\t/,"\t").gsub(/\\n/,"\",\n \"") + "\n].join(\"\\n\")"
    end).join(",\n\n")+
    "\n\n});\n//}}}\n"
  end

  def copy_all_tiddlers_from(file_name)
    make_tw { source_file file_name }.tiddlers.each do |t|
      add_tiddler t
    end
  end

end

# for funky DSL use
def make_tw(&block)
  TiddlyWiki.new(&block)
end


