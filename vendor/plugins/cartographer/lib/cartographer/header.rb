# Defines a map header
#
# <%= GMap::Header.new('example.com').to_s %>  
# or
# <%= GMap::Header.header_for(request) %>
# for a request-by-request basis.
#
# Insert the Google Map script into the header of your app.
# Allows for the IE extension for polyline drawing.

class Cartographer::Header
  attr_accessor :uri, :version
  @@keys = YAML.load(File.new("#{RAILS_ROOT}/config/cartographer-config.yml"))
  @version = 2

  def header_keys
    @@keys  
  end
    
  def has_key?(uri)
    @@keys.has_key?(uri)
  end
    
  def value_for(uri)
    @@keys[uri]
  end
    
  def to_s

    # initialize the html with the IE polyline VML code
    html = "\n<!--[if IE]>\n<style type=\"text/css\">v\\:* { behavior:url(#default#VML); }</style>\n<![endif]-->"

    # check if our URI is in the keys yml file and show the appropriate script
    if has_key?(@uri)
      html << "<script src='http://maps.google.com/maps?file=api&amp;v=#{version}&amp;key=#{value_for(@uri)}' type='text/javascript'></script>"
    else
      html << "<!-- Cartographer Header goes here.  The URI [#{@uri}] couldn't be found in your 
      cartographer-config.yml file.  Please add it and your map initialization code will
      appear here. Otherwise, perhaps your YML is misformed -->"
    end
    return html
  end

  # get a meaningful header out of the request object
  # strip the file, just the path, ma'am.
  # such that http://blah.com/path/file becomes /path/
  def self.header_for(request, version=2)
    mh = self.new
    mh.version = version
    #uri = request.request_uri
    #uri = uri[0..uri.rindex('/')] if uri.rindex('/') < uri.length
    mh.uri = request.env["HTTP_HOST"] #+ uri
    mh.to_s
  end

end
