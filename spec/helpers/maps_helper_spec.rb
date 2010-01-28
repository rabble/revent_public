require File.dirname(__FILE__) + '/../spec_helper.rb'

describe MapsHelper do
  before do
    @event = new_event(:latitude => '40', :longitude => '40')
    helper.stub!(:render_to_string).and_return('yay')
  end
  it "should generate a map instance from a mappable event" do
    map = helper.cartographer_gmap(@event)
    map.should be_a_kind_of(Cartographer::Gmap)
  end
  it "should generate nothing from a non-mappable event" do
    event = new_event
    helper.cartographer_gmap(event).should be_false
  end

  it "should target the map to a requested div id" do
    helper.cartographer_gmap(@event, :target => "your_tie").to_html.should match(/your_tie/ )

  end
  it "should center the map on the event location" do
    helper.cartographer_gmap(@event).to_html.should match(/GLatLng.40.0, 40.0/ )
  end
  it "should use a local zoom level" do
    helper.cartographer_gmap(@event).to_html.should match(/GLatLng.{1,20}, 15\D/ )
  end

  it "should map multiple events" do
    helper.cartographer_gmap([@event]).should be_a_kind_of(Cartographer::Gmap)
  end

  describe "when centering" do

    it "should set center to default" do
      helper.map_center( [] ).should == MapsHelper::CENTER_OF_USA
    end

    it "accepts a passed value" do
      helper.map_center( [], :center => [ 50, 50 ] ).should == [ 50, 50 ]
    end
    it "should accept a zip center" do
      ZipCode.should_receive :find_by_zip
      helper.postal_code_center('94110')
    end
    it "can distinguish Canada zip from US" do
      GeoKit::Geocoders::MultiGeocoder.should_receive(:geocode).and_return(stub('response', :success => false))
      helper.postal_code_center('B5B 4I4')
    end
    it "returns centers for Canada zips" do
      geoloc = GeoKit::GeoLoc.new :lat => 44.802814, :lng => -76.157341
      geoloc.success = true
      GeoKit::Geocoders::MultiGeocoder.stub!(:geocode).and_return(geoloc)
      helper.postal_code_center('B5B 4I4').should == [ 44.802814, -76.157341]
    end
    it "returns centers for states" do
      helper.map_center( [], :state => 'MI' ).should == [ 43.7711, -84.9243 ] 
    end
    it "centers on the event if only 1 event is given" do
      helper.map_center( [ @event ] ).should == [ 40, 40 ]
    end
  end

  describe "zoominess" do
    it "depends on the state when a state is set" do
      helper.map_zoom([], :state => 'CA').should == DaysOfAction::Geo::STATE_ZOOM_LEVELS[:CA]
    end
    it "is constant for zip lookups" do
      helper.map_zoom([], :zip => '94110').should == MapsHelper::ZOOM_LEVELS[:zip]
    end
    it "is constant for single events" do
      helper.map_zoom([new_event]).should == MapsHelper::ZOOM_LEVELS[:local]
    end
    it "defaults to really far far away" do
      helper.map_zoom([]).should == MapsHelper::ZOOM_LEVELS[:country]
    end
  end

  describe "multiple events" do
    it "should set name" do
      helper.marker_options(new_event, stub('icon', :name => 'iconz')).should have_key(:position)
    end
    it "should set info window" do
      helper.marker_options(new_event, stub('icon', :name => 'iconz')).should have_key(:info_window)
    end

  end
end
