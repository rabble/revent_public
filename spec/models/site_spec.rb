require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Site do
  describe "config_path" do
    it "should return a path in sites folder if given an id" do
      Site.config_path(1).should =~ /sites\/1/
    end
    it "should return a path in sites folder if given an id" do
      Site.config_path.should_not =~ /sites/
    end
  end
  describe "current_config_path" do
    it "should return a path in sites folder if given an id" do
      Site.current = Site.new
      Site.current.id = 1
      Site.current_config_path.should == Site.config_path(1)
    end
  end

  describe "flickr" do
    before do
      @test_config_path = File.join(RAILS_ROOT, "test", "config" )
      Site.stub!(:current_config_path).and_return(@test_config_path)
      @site = create_site
      Site.stub!(:current).and_return( @site )
    end
    it "calls file exist" do
      File.should_receive(:exist?).with( File.join( @test_config_path, 'flickr','test', 'flickr.yml' ))
      Site.flickr
    end
  end
end
