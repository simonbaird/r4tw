#
# =r4tw
# Author:: Simon Baird
# URL:: http://simonbaird.com/r4tw/
# r4tw is some ruby classes for manipuating TiddlyWikis and tiddlers.
# It is similar to cook and ginsu but much cooler.
#
# <i>$Rev$</i>


#---------------------------------------------------------------------
#-- General purpose utils

require 'pathname'
require 'open-uri'

def read_file(file_name) #:nodoc:
  File.read(file_name)
end

def fetch_url(url) #:nodoc:
  open(url).read.to_s
end

def this_dir(this_file=$0) #:nodoc:
  Pathname.new(this_file).expand_path.dirname
end

class String
  def to_file(file_name) #:nodoc:
    File.open(file_name,"w") { |f| f << self }
  end
end


#---------------------------------------------------------------------
#-- TiddlyWiki related utils

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

  def readBrackettedList
    # scan is a beautiful thing
    scan(/\[\[([^\]]+)\]\]|(\S+)/).map {|m| m[0]||m[1]}
  end  

  def toBrackettedList
    self
  end

  # was using this for test units but actually I don't think it's needed any more
  def eat_ctrl_m!
    gsub!("\x0d",'')
  end

end

class Array

  def toBrackettedList
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
    
  def Time.convertFromYYYYMMDDHHMM(date_string)
    m = date_string.match(/(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/)
    Time.utc(m[1],m[2],m[3],m[4],m[5])        
  end
    
end


#---------------------------------------------------------------------
# Tiddler
#

# =Tiddler
# For creating and manipulating tiddlers
# ===Example
#  puts Tiddler.new.from_scratch('tiddler'=>'Hello','text'=>'Hi there').to_s

class Tiddler

  @@main_fields = %w[tiddler modifier modified created tags]
  # and soon to be changecount?

  # text is not really a field in TiddlyWiki it makes
  # things easier to make it one here.  It could possibly
  # clash with a real field called text.  This might be a
  # serious problem but I will ignore it for now...

  @@defaults = {
      'tiddler'  => 'New Tiddler',
      'modified' => Time.now.convertToYYYYMMDDHHMM,
      'created'  => Time.now.convertToYYYYMMDDHHMM,
      'modifier' => 'YourName',
      'tags'     => '',
      'text'     => '', 
  }

  # used by from_file
  @@default_ext_tag_map = {
      '.js'      => %[systemConfig],
      '.html'    => %[html],
      '.css'     => %[css],
      '.pub'     => %[contentPublisher],
      '.palette' => %[palette],
  }
  
  attr_accessor :fields

  #
  # New by itself doesn't do much so instead you usually use one of these:
  # * Tiddler.new.from_scratch
  # * Tiddler.new.from_div
  # * Tiddler.new.from_file
  # * Tiddler.new.from_url
  # * Tiddler.new.from_remote_tw
  #
  def initialize
        @fields = {}
  end

  #
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
    @fields['tags'] &&= @fields['tags'].toBrackettedList # in case it's an array
    self
  end

  #
  # Creates a tiddler from a string containg an html div such as
  # would be found in a TiddlyWiki storeArea
  #
  def from_div(div_str)
    match_data = div_str.match(/<div([^>]+)>(.*?)<\/div>/m)
    field_str = match_data[1]
    text_str = match_data[2]

    text_str.sub!(/\n<pre>/,'')
    text_str.sub!(/<\/pre>\n/,'')

    field_str.scan(/ ([\w\.]+)="([^"]+)"/) do |field_name,field_value|
      if field_name == "title"
        field_name = "tiddler"
      end
      @fields[field_name] = field_value
    end

    @fields['text'] = text_str.unescapeLineBreaks.decodeHTML

    self
  end

  #
  # Creates a tiddler from a file.
  # Does some guessing about tags based on the file's extension
  # 
  def from_file(file_name, ext_tag_map=@@default_ext_tag_map)
    ext = File.extname(file_name)
    base = File.basename(file_name,ext)
    @fields = @@defaults.dup
    @fields['tiddler'] = base
    @fields['text'] = read_file(file_name)
    @fields['modified'] = File.mtime(file_name).convertToYYYYMMDDHHMM
    @fields['created'] = @fields['modified']
    @fields['tags'] = ext_tag_map[ext].toBrackettedList if ext_tag_map[ext]
    self
  end

  #
  # Creates a tiddler from a url. The entire contents of the page are the contents
  # of the tiddler.
  # You should set the 'tiddler' field and other fields using the field param
  # There is no automatic tagging for this one. 
  # 
  def from_url(url,fields={})
    @text = fetch_url(url)
    @fields = @@defaults.merge(fields)    
    self
  end

  #
  # Reads a tiddler from a remote TiddlyWiki file specified by a url
  # with a #TiddlerName appended, eg
  #  Tiddler.new.from_remote_tw("http://www.tiddlywiki.com/#HelloThere")
  #
  def from_remote_tw(url)
    tiddler_name = url.split("#").last
    ## XXX want to make it TiddlyWiki.new.from_url(url)
    puts url
    puts tiddler_name
    make_tw{ source_url(url) }.get_tiddler(tiddler_name)
  end

  # Returns a hash containing the tiddlers extended fields
  # Probably would include changecount at this stage at least
  def extended_fields
    @fields.keys.reject{ |f| @@main_fields.include?(f) || f == 'text' }.sort
  end

  # Converts to a div suitable for a TiddlyWiki store area
  def to_s(use_pre=false)

    fields_string =
      @@main_fields.
        reject{|f| f == 'modified' and !@fields[f]}.
        map { |f|
          # support old style tiddler=""
          # and new style title=""
          if f == 'tiddler' and use_pre
            field_name = 'title'
          else
            field_name = f
          end
          %{#{field_name}="#{@fields[f]}"}
        } +
      extended_fields.
        map{ |f| %{#{f}="#{@fields[f]}"} }    

    if use_pre
      "<div #{fields_string.join(' ')}>\n<pre>#{@fields['text'].encodeHTML}</pre>\n</div>"
    else
      "<div #{fields_string.join(' ')}>#{@fields['text'].escapeLineBreaks.encodeHTML}</div>"
    end

  end

  # Same as to_s
  def to_div(use_pre=false)
    to_s(use_pre)
  end

  # Lets you access fields like this:
  #  tiddler.name
  #  tiddler.created
  # etc
  #
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
      raise "No such field or method #{method}"
    end

  end

  # Add some text to the end of a tiddler's content
  def append_content(new_content)
    @fields['text'] += new_content
    self
  end
  
  # Add some text to the beginning of a tiddler's content
  def prepend_content(new_content)
    @fields['text'] = new_content + @fields['text']
    self
  end
  
  # Renames a tiddler
  def rename(new_name)
    @fields['tiddler'] = new_name
    self
  end

  # Makes a copy of this tiddler
  def copy
    Tiddler.new.from_div(self.to_div)
  end

  # Makes a copy of this tiddler with a new title
  def copy_to(new_title)
    copy.rename(new_title)
  end
  
  # Adds a tag
  def add_tag(new_tag)
    @fields['tags'] = @fields['tags'].
      readBrackettedList.
      push(new_tag).
      uniq.
      toBrackettedList

    self
  end

  # Adds a list of tags
  def add_tags(tags)
    tags.each { |tag| add_tag(tag) }
  end

  # Removes a single tag
  def remove_tag(old_tag)
    @fields['tags'] = @fields['tags'].
      readBrackettedList.
      reject { |tag| tag == old_tag }.
      toBrackettedList

    self
  end

  # Removes a list of tags
  def remove_tags(tags)
    tags.each { |tag| remove_tags(tag) }
  end

  # Returns true if a tiddler has a particular tag
  def has_tag(tag) 
    fields['tags'] && fields['tags'].readBrackettedList.include?(tag)
  end

  # Returns all tiddler slice
  def get_slices
    if not @slices
      @slices = {}
      # look familiar?
      slice_re = /(?:[\'\/]*~?(\w+)[\'\/]*\:[\'\/]*\s*(.*?)\s*$)|(?:\|[\'\/]*~?(\w+)\:?[\'\/]*\|\s*(.*?)\s*\|)/m
      text.scan(slice_re).each do |l1,v1,l2,v2|
        @slices[l1||l2] = v1||v2;
      end
    end
    @slices
  end

  # Returns a tiddler slice
  def get_slice(slice)
    get_slices[slice]
  end

  #
  # Experimental. Provides access to plugin meta slices.
  # Returns one meta value or a hash of them if no argument is given
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

#---------------------------------------------------------------------
# =Tiddlywiki
# Create a manipulate TiddlyWiki files 
#

#####
##### Done cleaning up Tiddler but haven' started on this yet...
#####

class TiddlyWiki

  attr_accessor :orig_tiddlers, :tiddlers, :raw

  def initialize(use_pre=false)
    @use_pre = use_pre
    @tiddlers = []
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

    # stupid ctrl (\r) char
    #@raw.eat_ctrl_m!

    if @raw =~ /var version = \{title: "TiddlyWiki", major: 2, minor: 2/
      @use_pre = true
    end
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

  @@store_regexp = /^(.*<div id="storeArea">\n?)(.*)(\n?<\/div>\r?\n<!--.*)$/m # stupid ctrl-m \r char

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
    ## the old way, one tiddler per line...
    # store.strip.to_a
    ## the new way
    store.scan(/(<div ti[^>]+>.*?<\/div>)/m).map { |m| m[0] }
    # did I mention that scan is a beautiful thing?
  end

  def add_core_hack(regexp,replace)
    # this is always a bad idea... ;)
    @core_hacks.push([regexp,replace])
  end

  def get_orig_tiddlers
    tiddler_divs.map do |tiddler_div|
      Tiddler.new.from_div(tiddler_div)
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
    # not sure about this bit. breaks some tests if I put it in
    #((@use_pre and @tiddlers.length > 0) ? "\n" : "") +
    @tiddlers.sort_by{|t| t.name}.inject(""){ |out,t|out << t.to_div(@use_pre) << "\n"}
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
          t.text.chomp.dump.gsub(/\\t/,"\t").gsub(/\\n/,"\",\n \"").gsub(/\\#/,"#") + "\n].join(\"\\n\")"
    end).join(",\n\n")+
    "\n\n});\n//}}}\n"
  end

  def copy_all_tiddlers_from(file_name)
    make_tw { source_file file_name }.tiddlers.each do |t|
      add_tiddler t
    end
  end

end

#
# A short hand for DSL style TiddlyWiki creation. Takes a block of TiddlyWiki methods that get instance_eval'ed
#
def make_tw(&block)
  tw = TiddlyWiki.new
  if block
    tw.instance_eval(&block)
  end
  tw
end


