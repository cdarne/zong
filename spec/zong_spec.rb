require 'spec_helper'

describe Zong::Zongosaurus, "ack" do

  before :each do
    @mt_log = Zong::BaseLog.new '/home/cdarne/var/www/sendit.ldmobile.net/MO/logs/mt.log'
    @error_log = Zong::BaseLog.new '/home/cdarne/var/www/sendit.ldmobile.net/MO/logs/mt_error.log'
    @server_log = Zong::BaseLog.new '/home/cdarne/var/log/cherokee/cherokee.error'

    Zong::Outgoing.destroy
    @outgoing = Zong::Outgoing.create(
      :account_id => 1,
      :channel_id => 17,
      :status_id => 0,
      :creation_date => Time.now,
      :rcpt_to => "33629658846",
      :body => "test",
      :sign => "LDMobile",
      :schedule => Time.now
    )
  end

  after :each do
    @server_log.should_not be_changed
  end

  it "logs an error ('bad request') and returns a 400 HTTP status code if no parameters are sent" do
    Zong::Zongosaurus.new.ack.code.should eql(400)
    @error_log.last_line.should include("bad request")
  end

  it "logs an error ('unknown request') and returns a 400 HTTP status code SSID and MSISDN are defined but not ACTION or STATUS" do
    req = Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745
    req.code.should eql(400)
    @error_log.last_line.should include("unknown request")
  end

  describe "when processing an acknowledgement" do
    it "logs an error ('ignored acknowledgement') if ACTION parameters is not SMSMT" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :ACTION => 'TUTU'
      @error_log.last_line.should include("ignored acknowledgement")
    end

    it "logs an error ('WTF!? no error but no ref!?') returns a 400 HTTP status code if ACTION=SMSMT and if ERROR and REF are not defined" do
      req = Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :ACTION => 'SMSMT'
      req.code.should eql(400)
      @error_log.last_line.should include("no error reported but no ref was supplied")
    end

    it "logs an error if ACTION=SMSMT and ERROR is defined" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :ACTION => 'SMSMT', :ERROR => 'test'
      @error_log.last_line.should include("reported error")
      @error_log.last_line.should include("test")
    end

    it "logs an error with description if ACTION=SMSMT and if ERROR and DESCRIPTION are defined" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :ACTION => 'SMSMT', :ERROR => 'test', :DESCRIPTION => 'desc'
      @error_log.last_line.should include("reported error")
      @error_log.last_line.should include("test")
      @error_log.last_line.should include("desc")
    end

    it "logs an error and updates the outgoing status to 'non delivered' if ACTION=SMSMT and if ERROR and REF are defined" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :ACTION => 'SMSMT', :ERROR => 'test', :REF => @outgoing.id
      @error_log.last_line.should include("reported error")
      @error_log.last_line.should include("test")
      @outgoing.reload
      @outgoing.status_id.should eql(7)
      @mt_log.last_line.should include("|#{@outgoing.id}|")
        @mt_log.last_line.should include("|7-non delivered")
    end

    it "updates the outgoing status to 'acked' if ACTION=SMSMT and if ERROR is not defined and if REF is defined" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :ACTION => 'SMSMT', :REF => @outgoing.id
      @outgoing.reload
      @outgoing.status_id.should eql(2)
      @mt_log.last_line.should include("|#{@outgoing.id}|")
        @mt_log.last_line.should include("|2-acked")
    end
  end

  describe "when proccessing an delivery report" do
    it "logs an error ('Unknown status') if status is not known" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :STATUS => 'WOOLOO'
      @error_log.last_line.should include("Unknown status")
    end

    it "updates the outgoing status to 'delivered' if STATUS='delivered' and REF is defined" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :STATUS => 'delivered', :REF => @outgoing.id
      @outgoing.reload
      @outgoing.status_id.should eql(5)
      @mt_log.last_line.should include("|#{@outgoing.id}|")
        @mt_log.last_line.should include("|5-delivered")
    end

    it "logs an error ('Delivery report failed') if STATUS=failed" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :STATUS => 'failed'
      @error_log.last_line.should include("Delivery report failed")
    end

    it "updates the outgoing status to 'non delivered' if STATUS='failed' and REF is defined and CAUSE is undefined" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :STATUS => 'failed', :REF => @outgoing.id
      @error_log.last_line.should include("Delivery report failed")
      @outgoing.reload
      @outgoing.status_id.should eql(7)
      @mt_log.last_line.should include("|#{@outgoing.id}|")
        @mt_log.last_line.should include("|7-non delivered")
    end

    [
      ['Deleted', 1000], ['Expired', 1001], ['Credit', 1002,], ['abandoned', 1003], ['barred', 1004],
      ['unknown-subscriber', 1005], ['invalid-subscriber', 1006], ['absent', 1007], ['refused', 1008],
      ['error-in-ms', 1009], ['memcap', 1010], ['cugrej', 1011], ['busy', 1012], ['roam', 1013],
      ['temp', 1014], ['unknown', 1015]
    ].each do |label, code|
      it "updates the outgoing status to '#{label}' if STATUS='failed' and if REF is defined and CAUSE=#{label}" do
        Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :STATUS => 'failed', :REF => @outgoing.id, :CAUSE => label
        @error_log.last_line.should include("Delivery report failed")
        @outgoing.reload
        @outgoing.status_id.should eql(code)
        @mt_log.last_line.should include("|#{@outgoing.id}|")
          @mt_log.last_line.should include("|#{code}-#{label}")
      end
    end

    it "updates the outgoing status to 'buffered' if STATUS='buffered' and REF is defined" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :STATUS => 'buffered', :REF => @outgoing.id
      @outgoing.reload
      @outgoing.status_id.should eql(1016)
      @mt_log.last_line.should include("|#{@outgoing.id}|")
        @mt_log.last_line.should include("|1016-buffered")
    end

    it "logs an error ('Delivery report unknown') if STATUS=unknown and REF is undefined" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :STATUS => 'unknown'
      @error_log.last_line.should include("Delivery report unknown")
    end

    it "updates the outgoing status to 'lost notification' if STATUS='unknown' and REF is defined" do
      Zong::Zongosaurus.new.ack :SSID => 5, :MSISDN => 33628647745, :STATUS => 'unknown', :REF => @outgoing.id
      @error_log.last_line.should include("Delivery report unknown")
      @outgoing.reload
      @outgoing.status_id.should eql(6)
      @mt_log.last_line.should include("|#{@outgoing.id}|")
        @mt_log.last_line.should include("|6-lost notification")
    end
  end

end
