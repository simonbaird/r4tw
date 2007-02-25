#
# r4tw
# By Simon Baird
# Revision $Rev$
# Ruby classes for manipuating TiddlyWikis and tiddlers 
# similar to cook and ginsu but cooler
#

require 'pathname'
require 'open-uri'

#
# Some handy bits and pieces
#

def read_file(file_name)
  File.read(file_name)
end

class String
  def to_file(file_name)
    File.open(file_name,"w") { |f| f << to_s }
  end
end

def fetch_url(url)
  open(url).read.to_s
end

def read_from(where)
  if where =~ /^(ftp|http|https):\/\//
    fetch_url(where)
  else
    read_file(where)
  end
end

def this_dir
  Pathname.new($0).expand_path.dirname
end

#
# TiddlyWiki related utils
#

class String 
 
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

  def eat_ctrl_m!
    gsub!("\x0d",'')
  end

end

class Array
  def toBracketedList
    map{ |i| (i =~ /\s/) ? ("[["+i+"]]") : i }.join(" ")
  end    
end

class Time
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
# Tiddler
# 

class Tiddler

  @@main_fields = %w[tiddler modifier modified created tags]

  @@defaults = {
      'tiddler'  => 'New Tiddler',
      'modified' => Time.now.convertToYYYYMMDDHHMM,
      'created'  => Time.now.convertToYYYYMMDDHHMM,
      'modifier' => 'YourName',
      'tags'     => '',
  }
  
  attr_accessor :fields, :text

  def self.method_missing(method_name,*args);
    case method_name.to_s
    when /^new_(.*)$/
      self.new.send($1,*args);
    end
  end

  def initialize
        @fields = @@defaults
        @text = ""
        @raw = ""
  end

  def from_scratch(fields={},text="")
    @fields = @@defaults.merge(fields)
    @text = text
    self
  end

	# Create a tiddler from a string containing a tiddler div
  def from_div(div)
    @raw = div
    @fields = {}
    match_data = div.match(/<div([^>]+)>([^<]*)<\/div>/)
    field_string = match_data[1]
    @text = match_data[2].unescapeLineBreaks.decodeHTML
    field_string.scan(/ ([\w\.]+)="([^"]+)"/) do |name,value|
      @fields[name] = value
    end
    self
  end

  def from_remote_tiddlywiki(url)
    tiddler_name = url.split("#").last
    make_tw { source_empty(url) }.get_tiddler(tiddler_name)
  end
  
  def from(location,fields={})
    # sense what to do based on the location
    if location =~ /^https?:/
      if location =~ /#/
        from_remote_tiddlywiki(location) # maybe should do fields here too
      else
        from_url(location,fields)
      end
    else
      from_file(location,fields)
    end
  end
  
  def append_content(new_content)
    @text += new_content
  end

  def rename(new_name)
    @fields['tiddler'] = new_name
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

  def extra_fields
    @fields.keys.reject{ |f| @@main_fields.include?(f)}.sort
  end
    
  def to_div
    fields_text = @@main_fields.map { |f| %{#{f}="#{@fields[f]}"} } +
      extra_fields.map{ |f| %{#{f}="#{@fields[f]}"} }    
    %{<div #{fields_text.join(' ')}>#{@text.escapeLineBreaks.encodeHTML}</div>}
  end

  def method_missing(method,*args)

    method = method.to_s

    synonyms = {
      'name' => 'tiddler',
      'title' => 'tiddler'
    }

    method = synonyms[method] || method

    if @@main_fields.include? method or @fields[method]
      @fields[method]
    else
      raise "No such tiddler method #{method}"
    end

  end

  def add_tag(new_tag)
    fields['tags'] = fields['tags'].
      readBracketedList.
      push(new_tag).
      uniq.
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

  def plugin_meta(slice=nil)
    # see http://www.tiddlywiki.com/#ExamplePlugin
    if not @plugin_meta
      meta = %w[
        Name
        Description
        Version
        Date
        Source
        Author
        License
        CoreVersion
        Browser
      ]
      @plugin_meta = get_slices.reject{|k,v| not meta.include?(k)}
    end
    if slice
      @plugin_meta[slice]
    else
      @plugin_meta
    end
  end

  def remove_tag(old_tag)
    fields['tags'] = fields['tags'].
      readBracketedList.
      reject { |tag| tag == old_tag }.
      toBracketedList
    self
  end

end


#
# Tiddlywiki
# 

class TiddlyWiki

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
    add_tiddler Tiddler.new.from_remote_tiddlywiki(url)
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


