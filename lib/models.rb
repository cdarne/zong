require 'dm-core'

#DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'postgres://sendit:sendit@localhost/sendit_db')
adapter = DataMapper.repository(:default).adapter

module Zong
  class Outgoing
    include DataMapper::Resource

    storage_names[:default] = 'outgoing'

    property :id, Serial, :field => 'outgoing_id'
    property :account_id, Integer
    property :channel_id, Integer
    property :status_id, Integer
    property :subtype, Integer
    property :creation_date, DateTime
    property :rcpt_to, String
    property :contact, String
    property :subject, Text
    property :body, Text
    property :sign, Text
    property :schedule, DateTime
    property :push_date, DateTime
    property :acked_date, DateTime
    property :retries, Integer
    property :timeout, DateTime
    property :request_status, Text
    property :peer_id, String
    property :peer_status, String
    property :peer_message, Text
    property :campaign_id, Integer
    property :operator_id, Integer

    has 1, :push
  end

  class Push
    include DataMapper::Resource

    storage_names[:default] = 'push'

    property :id, Serial, :field => 'push_id'
    belongs_to :outgoing
    property :channel, Integer
    property :priority, Integer
    property :rcpt_to, String, :length => 100
    property :contact, String, :length => 100
    property :subject, Text
    property :body, Text
    property :sign, Text
    property :schedule, DateTime
  end

  class Status
    include DataMapper::Resource

    storage_names[:default] = 'status'

    property :id, Serial, :field => 'status_id'
    property :name, String, :length => 50

    has 1, :sms_status
  end

  class SmsStatus
    include DataMapper::Resource

    storage_names[:default] = 'sms_status'

    property :id, Serial, :field => 'sms_status_id'
    belongs_to :status
    property :label, String, :length => 30
    property :reason, String
    property :indication_ptt, String, :length => 80
    property :explanation, String
  end

  def add_a_push
    outgoing      = Outgoing.new(
        :account_id    => 1,
        :channel_id    => 17,
        :status_id     => 0,
        :creation_date => Time.now,
        :rcpt_to       => "33629658846",
        :body          => "test",
        :sign          => "LDMobile",
        :schedule      => Time.now
    )

    push          = Push.new(
        :channel  => 17,
        :priority => 1,
        :rcpt_to  => "33629658846",
        :body     => "test",
        :sign     => "LDMobile",
        :schedule => Time.now
    )

    push.outgoing = outgoing
    push.save
  end

  def add_statuses

    id            = 1000

    SmsStatus.all(:status => [{:id.gte => id}]).destroy
    Status.all(:id.gte => id).destroy

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'deleted',
        :reason         => 'Deleted before delivery',
        :indication_ptt => 'Permanent',
        :explanation    => 'Deleted before delivery (e.g. due to maximal subscriber charging restriction being exceeded). Note: this is expectable and may happen from time to time. In certain countries, it may even consistently happen on CAT=reg, but your server is still required to send this CAT=reg.')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'expired',
        :reason         => 'Expired (validity period exceeded)',
        :indication_ptt => 'Permanent',
        :explanation    => 'Expired (validity period exceeded)')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'credit',
        :reason         => 'Recipient subscriber is out of prepaid credit',
        :indication_ptt => 'Permanent',
        :explanation    => 'Recipient subscriber is out of prepaid credit')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'abandoned',
        :reason         => 'Delivery abandoned',
        :indication_ptt => 'Permanent',
        :explanation    => 'Delivery abandoned')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'barred',
        :reason         => 'Service barred for subscriber',
        :indication_ptt => 'Permanent',
        :explanation    => 'Service barred for subscriber')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'unknown-subscriber',
        :reason         => 'Recipient MSISDN is unknown',
        :indication_ptt => 'Permanent',
        :explanation    => 'Recipient MSISDN is unknown (e.g. unallocated MSISDN)')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'invalid-subscriber',
        :reason         => 'Recipient MSISDN is invalid',
        :indication_ptt => 'Permanent',
        :explanation    => 'Recipient MSISDN is invalid (e.g. malformed or not valid numbering plan)')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'absent',
        :reason         => 'Subscriber is absent',
        :indication_ptt => 'Temporary',
        :explanation    => 'Subscriber is absent')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'refused',
        :reason         => 'Registration actively refused by subscriber',
        :indication_ptt => 'Permanent',
        :explanation    => 'Registration actively refused by subscriber')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'error-in-ms',
        :reason         => "Error in mobile station",
        :indication_ptt => 'Temporary',
        :explanation    => "Error in mobile station (handset)")
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'memcap',
        :reason         => "Recipient handset's memory capacity exceeded",
        :indication_ptt => 'Temporary',
        :explanation    => "Recipient handset's memory capacity exceeded (subscriber should erase a few SMS before being able to receive further ones)")
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'cugrej',
        :reason         => 'Closed user group reject',
        :indication_ptt => 'Permanent',
        :explanation    => 'Closed user group reject')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'busy',
        :reason         => 'Recipient handset is busy',
        :indication_ptt => 'Temporary',
        :explanation    => 'Recipient handset is in "SMS busy" condition and can temporarily not receive SMS')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'roam',
        :reason         => 'Roaming restriction',
        :indication_ptt => 'Temporary',
        :explanation    => 'Roaming restriction')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'temp',
        :reason         => 'Temporary failure',
        :indication_ptt => 'Temporary',
        :explanation    => 'Temporary failure')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'error')
    sms_st        = SmsStatus.new(
        :label          => 'unknown',
        :reason         => 'Unknown cause code',
        :indication_ptt => 'Unknown',
        :explanation    => 'Unknown cause code')
    sms_st.status = st
    sms_st.save

    id            = id + 1

    st            = Status.new(:id => id, :name => 'processing')
    sms_st        = SmsStatus.new(
        :label          => 'buffered',
        :reason         => 'The SMS-MT is still buffered on ZONG',
        :indication_ptt => 'Intermediate',
        :explanation    => "The SMS-MT is still buffered on ZONG or on the carrier's network, and delivery to its recipient will be retried later. This is an intermediate notification.")
    sms_st.status = st
    sms_st.save

  end
end