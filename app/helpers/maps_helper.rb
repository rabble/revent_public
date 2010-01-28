module MapsHelper
  @map_marker_icon = 'http://s3.amazonaws.com/events.radicaldesigns.org/images/green_dot.png'
  CENTER_OF_USA = [37.160317,-95.800781]
  ZOOM_LEVELS = { :country => 3, :local => 15, :zip => 12 }

  # available options are 
  # * :target ( the id of the div for the map )
  # * :zip ( to center on )
  # * :state ( to center on )
  # * :center ( [ lat, long ] center hand-set )
  def cartographer_gmap(event, options = {} )
    options[:target] ||= 'eventmap'
    if event.respond_to?(:latitude) && event.respond_to?(:longitude) && !(event.latitude && event.longitude)
      return false
    end

    events = event.respond_to?(:each) ? event : [event]

    map = Cartographer::Gmap.new options[:target]
    initialize_map map, map_options(events, options)
    icon = Cartographer::Gicon.new( 
                    :image_url => @map_marker_icon, 
                    :shadow_url => '', 
                    :width => 10, 
                    :height => 10, 
                    :anchor_x => 5, 
                    :anchor_y => 5 )
    events.each do |ev|
      next unless ev.latitude && ev.longitude
      map.markers << Cartographer::Gmarker.new( marker_options(ev, icon) )
    end
    map.icons << icon
    map
  end

  def marker_options(event, icon)
    options = { :position => [event.latitude, event.longitude], 
                :icon => icon.name, 
                :name => "event_#{event.id}_marker",
                :info_window => info_window(event)
    }
  end

  def info_window(event)
    if respond_to?(:render_to_string)
      render_to_string(:partial => 'info_window', :locals => {:event => event})
    else
      controller.send(:render_to_string, :partial => 'events/info_window', :locals => {:event => event})
    end
  end

  def initialize_map(map, options)
    map.init do |m|
      m.center = options[:center]
      m.controls = [:zoom, :large]
      m.zoom = options[:zoom]
    end
  end

  def map_options(events, options)
    { :center => map_center(events, options),
      :zoom => map_zoom(events, options) }
  end

  def postal_code_center(code)
    if code =~ /^\D\d\D((-| )?\d\D\d)?$/ # Canadian postal code
      geo = GeoKit::Geocoders::MultiGeocoder.geocode(code)
      center, @state = [geo.lat, geo.lng], geo.state if geo.success
      return center
    end
    zip = ZipCode.find_by_zip code
    if zip
      @state = zip.state
      [ zip.latitude, zip.longitude ]
    end
  end

  def map_center(events, options={})
    return options[:center] if options[:center]
    if options[:zip] && zip_center = postal_code_center( options[:zip] )
      return zip_center
    end
    if options[:state]
      return DaysOfAction::Geo::STATE_CENTERS[options[:state].to_sym]
    end
    return CENTER_OF_USA unless events.length == 1
    [events.first.latitude, events.first.longitude]
  end

  def map_zoom( events, options = {} )
    return DaysOfAction::Geo::STATE_ZOOM_LEVELS[options[:state].to_sym] unless options[:state].blank?
    return ZOOM_LEVELS[:zip] if options[:zip]
    return ZOOM_LEVELS[:local] if events.length == 1
    return ZOOM_LEVELS[:country]
  end
end

