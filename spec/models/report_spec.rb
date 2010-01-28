require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Report do
  describe "create" do 
    before do
      @site = create_site
      @site.stub!(:salesforce_enabled?).and_return(false)
      Site.stub!(:current).and_return(@site)
      @calendar = create_calendar(:site => @site, :flickr_photoset => '1234567890', :flickr_tag => 'testing')
      @event = create_event( :calendar => @calendar, :country_code => 'GBR' )
      Akismet.stub!(:new).and_return(stub(Akismet, :comment_check => true, :last_response => true))
    end

    describe "user" do
      before do
        @user = create_user :first_name => 'foxy', :email => 'test@example.com', :site => @site
      end

      it "should update if user exists" do
        @report = create_report :reporter_data => {:first_name => 'testy', :last_name => 'mctest', :email => 'test@example.com'}, :event => @event, :user => nil
        @user.reload.first_name.should == 'testy'
      end

      it "should set the report user to the existing user" do
        @report = new_report :event => @event, :user => nil
        @report.reporter_data = {:first_name => 'testy', :last_name => 'mctest', :email => 'test@example.com'}
        @report.save!
        @report.reload.user_id.should == @user.id
      end

      it "should set the user on create" do
        @report = Report.create(:event => @event, :reporter_data => {:first_name => 'testy', :last_name => 'mctest', :email => 'test@example.com'})
        @report.user_id.should == @user.id
      end

      it "should create new users" do
        @report = Report.create :reporter_data => {:first_name => 'testy', :last_name => 'mctest', :email => 'new@example.com'}, :event => @event
        User.find(:first, :conditions => { :email => 'new@example.com', :site_id => @site }).should == @report.user
      end

      it "should assign new users a random password" do
        @report = new_report
        @report.reporter_data = {:first_name => 'testy', :last_name => 'mctest', :email => 'newpassword@example.com'}
        @report.user.crypted_password.should_not be_nil
      end
    end

    describe "press links" do
      before do
        @press_params  = {'1' => {:url => 'http://example.com', :text => 'the example site'}, '2' => {:url => 'http://other.example.com', :text => 'another one'}}
        @report = create_report(:press_link_data => @press_params )
      end
      it "should create press links" do
        @report.press_links(true).collect {|link| link.url}.should include('http://example.com')
      end
      it "should create correct data" do
        @report.press_links.first.text.should == 'the example site'
      end
     end

    describe "attachment" do
      before do
        @uploaded_data = test_uploaded_file
      end
      it "should create attachments" do
        @report = create_report(:attachment_data => {'0' => {:caption => 'attachment 0', :uploaded_data => @uploaded_data}})
        File.exist?(@report.attachments(true).first.full_filename).should be_true
      end
      it "should create multiple attachments" do
        @report = new_report(:attachment_data => {'0' => {:caption => 'attachment 0', :uploaded_data => test_uploaded_file}, '1' => {:caption => 'attachment 1', :uploaded_data => test_uploaded_file}})
        @report.make_local_copies!
        @report.move_to_temp_files!
        @report.save
        @report.attachments(true).all? {|a| File.exist?(a.full_filename)}.should be_true
      end
      it "should tag attachments" do
        pending 'tagging not high priority now; get this working later'
        @report = create_report(:attachment_data => {'0' => {:caption => 'attachment 0', :uploaded_data => @uploaded_data, :tag_depot => {'0' => 'tag1', '1' => 'tag2'}  }})
        @report.attachments.tags.should_not be_empty
      end
    end

    it "should validate all associated models" do
      @report = create_report(:press_link_data => {'1' => {:url => '#++ &&^ %%$', :text => 'invalid url'}})
      @report.valid?.should_not be_true
    end

    describe "akismet" do
      it "should check akismet before uploading to flickr" do
        @report = new_report
        @report.should_receive(:check_akismet).and_return(true)
        @report.save
      end
    end

    describe "embeds" do
      before do
        @report = new_report
      end
      it "should accept embed data" do
        @report.embed_data = "blah"
        @report.embed_data.should == "blah"
      end
      it "should build embeds before saving" do
        @report.should_receive(:build_embeds).and_return(true)
        @report.save
      end
      it "should accept the standard params hash coming form" do
        @report.embed_data = {'1' => {:html => "<tag>", :caption => "yay"}, '2' => {:html => "<html>", :caption => "whoopee"}}
        @report.build_embeds
        @report.embeds.first.html.should == "<tag>"
      end
    end
    
    describe "build from hash" do
      describe "params hash with no attachments, embed, or press links" do
        before do
          @uploaded_data = test_uploaded_file
          @params = {:report => {:text => "text", :attendees => '100', :event => create_event,
                    :reporter_data => {:first_name => "hannah", :last_name => "barbara", :email => "hannah@example.com"},
                    :press_link_data => {'1' => {:url => '', :text => ''}, '2' => {:url => '', :text => ''}},
                    :attachment_data => {'1' => {:caption => '', :uploaded_data => nil }},
                    :embed_data => {'1' => {:html => "", :caption => ""}, '2' => {:html => "", :caption => ""}}}}
          @report = Report.create!(@params[:report].merge( :akismet_params => stub('request_object').as_null_object))
        end
        it "should not create attachments when no attachment data is provided" do
          @report.attachments.should be_empty
        end
        it "should not create embeds when no embed data is provided" do
          @report.embeds.should be_empty
        end
        it "should not create press links when no press link data is provided" do
          @report.press_links.should be_empty
        end
      end
      describe "full params hash" do
        before do
          @uploaded_data = test_uploaded_file
          @params = {:report => {:text => "text", :attendees => '100', :event => create_event,
                    :reporter_data => {:first_name => "hannah", :last_name => "barbara", :email => "hannah@example.com"},
                    :press_link_data => {'1' => {:url => 'http://example.com', :text => 'the example site'}, '2' => {:url => 'http://other.example.com', :text => 'another one'}},
                    :attachment_data => {'1' => {:caption => 'attachment 0', :uploaded_data => @uploaded_data}},
                    :embed_data => {'1' => {:html => "<tag>", :caption => "yay"}, '2' => {:html => "<html>", :caption => "whoopee"}}
                  }}
          @report = Report.create!(@params[:report].merge( :akismet_params => stub('request_object').as_null_object))
        end
        it "gets text" do
          @report.text.should == 'text'
        end
        it "saves successfully" do
          @report.id.should_not be_nil
        end
        it "should copy reporter data to user" do 
          @report.user.first_name.should == "hannah"
        end
        it "should create user" do 
          @report.user.id.should_not be_nil
        end
        it "should copy attachment data" do 
          @report.should_receive(:attachment_data=)
          @report.update_attributes(@params[:report])
        end
        it "should copy attachment data to attachment" do 
          @report.attachments.first.caption.should == "attachment 0"
        end
        it "should create attachment" do 
          @report.attachments.first.id.should_not be_nil
        end
        it "should create press links" do
          @report.press_links.first.url.should match(/example/)
        end
        it "should save said press links" do
          @report.press_links.first.id.should_not be_nil
        end
        it "should save embeds" do
          @report.embeds.first.id.should_not be_nil
        end
        it "should create embeds" do
          @report.embeds.first.html.should match(/tag/)
        end
      end
    end

    describe "upload attachments to flickr" do
      before do
        @upload_proxy = stub( 'uploads_proxy', :upload_image => true )
        @photo_proxy  = stub( 'photos_proxy', :upload => @upload_proxy )
        @photoset_proxy = stub( 'photoset_proxy', :addPhoto => true )
        @flickr_api = stub( 'flickr_api', :photos => @photo_proxy, :photosets => @photoset_proxy )
        Site.stub!(:flickr).and_return( @flickr_api )
        @attach = create_attachment(:primary => true, :temp_data => 'data data data')
        @report = create_report(:event => @event)
        @report.attachments << @attach
        @report.status = Report::PUBLISHED
      end
      it "does not work without a valid Flickr connection" do
        @upload_proxy.should_not_receive(:upload_image)
        Site.stub!(:flickr).and_return(false)
        @report.send_attachments_to_flickr
      end
      it "should not send unpublished items to flickr" do
        @report.stub!(:published?).and_return(false)
        @upload_proxy.should_not_receive(:upload_image)
        @report.send_attachments_to_flickr
      end
      it "should not send items that already have been uploaded"  do
        @report.attachments.first.flickr_id = "123"
        @upload_proxy.should_not_receive(:upload_image)
        @report.send_attachments_to_flickr
      end
      it "checks for metadata" do
        @report.should_receive(:flickr_title)
        @report.send_attachments_to_flickr
      end
      it "works from tempfiles or full files" do
        @attach.should_receive(:temp_data).and_return( false )
        @report.send_attachments_to_flickr
      end
      it "calls upload on the flickr api" do
        @upload_proxy.should_receive(:upload_image)
        @report.send_attachments_to_flickr
      end
      it "sets the flickr id attribute" do
        @upload_proxy.stub!(:upload_image).and_return(5)
        @attach.should_receive(:flickr_id=).with(5)
        @report.send_attachments_to_flickr
      end
      it "does not save if the flickr upload failed" do
        @upload_proxy.stub!(:upload_image).and_return false 
        @attach.should_not_receive(:save)
        @report.send_attachments_to_flickr
      end
      it "adds the photoset if the attachment is primary and the photoset is defined" do
        @upload_proxy.stub!(:upload_image).and_return('998988978')
        @photoset_proxy.should_receive(:addPhoto)
        @report.send_attachments_to_flickr
      end
      it "does not add the photoset if no photoset is defined" do
        @calendar.stub!(:flickr_photoset).and_return(nil)
        @photoset_proxy.should_not_receive(:addPhoto)
        @report.send_attachments_to_flickr
      end
      it "does not add the photoset if the attachment is not primary" do
        @calendar.stub!(:flickr_photoset).and_return( 5 )
        @report.attachments.first.primary = false
        @photoset_proxy.should_not_receive(:addPhoto)
        @report.send_attachments_to_flickr
      end
      it "rescues XMLRPC errors" do
        @flickr_api.stub!(:photos).and_raise( XMLRPC::FaultException.new( "problem", "yeah" ) )
        lambda{ @report.send_attachments_to_flickr }.should_not raise_error
      end
    end

    describe 'email trigger' do
      it "delivers a trigger if the calendar has no triggers but the site does" do
        TriggerMailer.should_receive(:deliver_trigger)
        @site.stub!(:triggers).and_return(stub('triggers', :any? => true, :find_by_name => true ))
        @report = new_report(:event => @event)
        @report.trigger_email
      end
    end
  end
end
