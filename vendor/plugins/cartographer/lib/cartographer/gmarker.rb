class Cartographer::Gmarker
  attr_accessor :name, :icon, :position, :click, :info_window, :map

  def initialize(options = {})
    @name = options[:name] || "marker"
    @position = options[:position] || [0, 0]
    @icon = options[:icon] || :normal
    @click = options[:click] # javascript to execute on click
    @info_window = options[:info_window] # html to pop up on click
    @map = options[:map]
    
    # inherit our 'debug' settings from the map, if there is one, and it's in debug
    # you can also just debug this marker, if you like, or debug the map and
    # not this marker.
    @debug = options[:debug] || (@map.respond_to?(:debug) ? @map.debug : false)
  end

  def lat
    @position[1]
  end

  def lon
    @position[0]
  end

  def header_js
    script = []
    if @info_window.kind_of?Array
      script << "  var #{@name}_infoTabs = ["
      script << @info_window.inject([]) { |tabs,tab|
        tabs << "   new GInfoWindowTab(\"#{tab[:title]}\",\"#{tab[:html]}\")"
      }.join(",\n")
      script << "  ]\n"
      script << "function #{@name}_infowindow_function(){
  #{@name}.openInfoWindowTabsHtml(#{@name}_infoTabs);
}\n"
    else        
      script << "function #{@name}_infowindow_function(){
  #{@name}.openInfoWindowHtml(\"#{@info_window}\")
}\n"
    end
  end

  def to_js
    script = []
    options = []
    if icon != :normal
      options << icon
    end
    gmarker_params = (["new GLatLng(#{@position[0]}, #{@position[1]})"] + options).join(',')
    script << "// Set up the pre-defined marker" if @debug
    script << "#{@name} = new GMarker(#{gmarker_params});\n"

    if @click
      script << "// Create the listener for your custom click event" if @debug
      script << "GEvent.addListener(#{name}, \"click\", function() {#{@click}});\n"
    else
      script << "GEvent.addListener(#{name}, \"click\", function() {#{name}_infowindow_function()});\n"
    end

    script << "  // Add the marker to a new overlay on the map" if @debug
    script << "  #{@map.dom_id}.addOverlay(#{@name});\n"
    return @debug? script.join("\n  ") : script.join.gsub(/\s+/, ' ')
  end

  def infowindow_link(link_text = 'Show on map', options = {})
    anchor = '#' + options[:anchor].to_s
    "<a href='#{anchor}' onClick='#{@name}_infowindow_function(); return false;'>#{link_text}</a>"
  end
	
  def zoom_link(link_text = 'Zoom on map')
    "<a href='#' onClick='#{@map.dom_id}.setCenter(new GLatLng(#{@position.first}, #{@position.last}), 8); return false;'>#{link_text}</a>"
  end
end
