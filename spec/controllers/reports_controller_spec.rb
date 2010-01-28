require File.dirname(__FILE__) + '/../spec_helper.rb'

describe ReportsController do
  describe 'create' do
    before do
      Site.stub!(:current).and_return(create_site)
      Site.current.stub!(:salesforce_enabled?).and_return(false)
      Site.stub!(:current_config_path).and_return(File.join(RAILS_ROOT,'test/config'))
      Site.current.calendars << create_calendar
      @uploaded_data = test_uploaded_file
      @create_params = {:report => {:text => "text", :attendees => '100', :event => create_event,
                :reporter_data => {:first_name => "hannah", :last_name => "barbara", :email => "hannah@example.com"},
                :press_link_data => {'1' => {:url => 'http://example.com', :text => 'the example site'}, '2' => {:url => 'http://other.example.com', :text => 'another one'}},
                :attachment_data => {'1' => {:caption => 'attachment 0', :uploaded_data => @uploaded_data}},
                :embed_data => {'1' => {:html => "<tag>", :caption => "yay"}, '2' => {:html => "<html>", :caption => "whoopee"}}
              }}
    end
    def act!
      post :create, @create_params
    end
    it "should save the report" do
      ReportWorker.should_receive(:async_save_report)
      act!
    end
  end
end
