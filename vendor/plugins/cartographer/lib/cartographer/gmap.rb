class Cartographer::Gmap
  attr_accessor :dom_id, :draggable, :polylines,:type, :controls,
  :markers, :center, :zoom, :icons, :debug

  @@window_onload = ""

  def initialize(dom_id)
    @dom_id = dom_id
    
    # disable dragging with :draggable => false
    @draggable = nil
    
    # can be one of :satellite, :hybrid or :normal (default)
    @type = :normal
    
    # set which controls are exposed: should be an array of any of 
    # :large, :small, :scale, :overview, :zoom, and/or :type
    #  :large, :small : sets the size of the controls
    #  :overview      : shows a small, collapsible overview map in the corner
    #  :zoom          : shows the zoom slider control
    #  :type          : shows the map type control (hybrid, satellite, normal)
    @controls = [ :zoom ]
    
    @center = [103.831787109375, 1.2413579498795726]
    @zoom = 8 # 0 is closest, and 8 is world-view.
    
    @move_delay = 2000
    @markers = []
    @polylines = []
    @icons = []
    @debug = false
  end

  def init
    yield self if block_given?
    return self
  end
  
  def to_html(include_onload = true)
    @window_onload = ""
    @markers.each { |m| m.map = self } # markers need to know their parent

    html = []
    # setup the JS header
    html << "<!-- initialize the google map and your markers -->" if @debug
    html << "<script type=\"text/javascript\">\n/* <![CDATA[ */\n"  
    html << to_js(include_onload)
    html << "/* ]]> */</script> "
    html << "<!-- end of cartographer code -->" if @debug
    return @debug ? html.join("\n") : html.join.gsub(/\s+/, ' ')
  end
  
  def to_js(include_onload = true)
    html = []
    html << "// define the map-holding variable so we can use it from outside the onload event" if @debug
    html << "var #{@dom_id};\n"

    html << "// define the marker variables for your map so they can be accessed from outside the onload event" if @debug
    @markers.collect do |m| 
      html << "var #{m.name};"
      html << m.header_js
    end
    
    html << "// define the map-initializing function for the onload event" if @debug
    html << "function initialize_gmap_#{@dom_id}() {
if (!GBrowserIsCompatible()) return false;
#{@dom_id} = new GMap2(document.getElementById(\"#{@dom_id}\"));
#{@dom_id}.setCenter(new GLatLng(#{@center[0]}, #{@center[1]}), #{@zoom});"

    html << "  #{@dom_id}.disableDragging();" if @draggable == false
    html << "  // set the default map type" if @debug 
    html << "  #{@dom_id}.setMapType(G_#{@type.to_s.upcase}_MAP);\n"

    html << "  // define which controls the user can use." if @debug 
   @controls.each do |control|
      html << "  #{@dom_id}.addControl(new " + case control
        when :large, :small, :overview
          "G#{control.to_s.capitalize}MapControl"
        when :scale
          "GScaleControl"
        when :type
          "GMapTypeControl"
        when :zoom
          "GSmallZoomControl"
      end + "());"
    end

    html << "  // create icons from the @icons array" if @debug
    @icons.each { |i| html << i.to_js }

    html << "\n  // create markers from the @markers array" if @debug
    @markers.each { |m| html << m.to_js }

    html << "  // create polylines from the @polylines array" if @debug
    @polylines.each { |pl| html << pl.to_js }
    
    # ending the gmap_#{name} function
    html << "}\n"
    html << "  // Dynamically attach to the window.onload event while still allowing for your existing onload events." if @debug

    # todo: allow for onload to happen before, or after, the existing onload events, like :before or :after
    if include_onload
      # all these functions need to be added to window.onload due to an IE bug
      @@window_onload << "gmap_#{@dom_id}();\n"

      html << "
if (typeof window.onload != 'function')
  window.onload = initialize_gmap_#{@dom_id};
else {
  old_before_cartographer_#{@dom_id} = window.onload;
  window.onload = function() { 
    old_before_cartographer_#{@dom_id}(); 
    initialize_gmap_#{@dom_id}() 
  }
}"      
    else #include_onload == false
      html << "initialize_gmap_#{@dom_id}();"
    end
    return @debug ? html.join("\n") : html.join.gsub(/\s+/, ' ')
  end
  
  def follow_route_link(link_text = 'Follow route', options = {})
    anchor = '#' + (options[:anchor].to_s || '')
    move_delay = (options[:delay] || @move_delay)
    "<a href='#{anchor}' onclick='follow_gmap_route_#{@dom_id}_function(#{move_delay}); return false;'>#{link_text}</a>"
  end    

  def to_s
    self.to_html
  end
  
  # returns the central position (midpoint) of your markers
  def auto_center
  	return nil unless @markers
      return @markers.first.position if @markers.length == 1
  	maxlat, minlat, maxlon, minlon = Float::MIN, Float::MAX, Float::MIN, Float::MAX
  	@markers.each do |marker| 
  		if marker.lat > maxlat then maxlat = marker.lat end
  		if marker.lat < minlat then minlat = marker.lat end
  		if marker.lon > maxlon then maxlon = marker.lon end 
  		if marker.lon < minlon then minlon = marker.lon end
  	end
  	return [((maxlat+minlat)/2), ((maxlon+minlon)/2)]
  end

end
