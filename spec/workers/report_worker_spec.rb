require File.dirname(__FILE__) + '/../spec_helper'

describe ReportWorker do
  before do
    Site.stub!(:current).and_return(new_site(:id => 1, :host => 'test.example.org'))
    @report = Report.new({:text => 'dope', :event_id => create_event.id, :reporter_data => {:email => 'dude@example.com'}, :akismet_params => {}})
  end
  it "should save the report with the report_params" do
    @report.should_receive(:save)
    ReportWorker.new.save_report( @report )
  end
  it "should set Site.current" do
    Site.should_receive(:current=)
    @report.stub!(:save)
    ReportWorker.new.save_report( @report )
  end

  it "ensures that a valid event is sent" do
    worker = ReportWorker.new
    worker.logger.should_receive(:warn)
    @report.event_id = 'jjj'
    worker.save_report( @report )
  end

  it "should create multiple attachments" do
    @uploaded_data = test_uploaded_file
    @report = new_report(:attachment_data => {'0' => {:caption => 'attachment 0', :uploaded_data => @uploaded_data}, '1' => {:caption => 'attachment 1', :uploaded_data => @uploaded_data}})
    @report.make_local_copies!
    ReportWorker.new.save_report(@report)
    @report.attachments(true).all? {|a| File.exist?(a.full_filename)}.should be_true
  end

  describe "on the queue" do
    it "should be marshalable" do
      @report.attachment_data = {'0' => {:uploaded_data => test_uploaded_file}}
      lambda { Marshal.dump @report }.should_not raise_error
    end
    it "should be marshal loadable" do
      @report.attachment_data = {'0' => {:uploaded_data => (@file = test_uploaded_file)}}
      @report.make_local_copies!
      data = Marshal.dump @report
      @file.close(true)
      r = Marshal.load data
      File.exist?(r.attachments.first.temp_path).should be_true
    end
  end
end
