require File.dirname(__FILE__) + '/../spec_helper'

describe ExportWorker do
  before(:all) do
    @site = create_site
    1.upto(3) {|i| create_user(:site => @site)}
    Site.stub!(:find).and_return(@site)
  end
  it "should export users to a csv file" do
    @start = Time.now.strftime("%Y%m%d%H%M%S")
    ExportWorker.new.export_users(:site_id => @site, :start => @start)
    @csvfile = File.join(RAILS_ROOT, 'tmp', "#{@site.theme}_users_#{@start}.csv")
    File.exists?(@csvfile).should be_true
  end
  after do
    FileUtils.rm @csvfile
  end
end
