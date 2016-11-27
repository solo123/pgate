require 'test_helper'

class SendNotifyJobTest < ActiveJob::TestCase
=begin
  test 'SendNotifyJob running' do
    n = Notify.new
    n.notify_url = 'abc'
    n.data = 'data123'
    n.status = 0
    n.sender = Client.last
    n.save
    SendNotifyJob.perform_now(n)
    assert_equal 7, n.status
  end
  test 'SendNotifyJob retry...' do
    n = Notify.new
    n.notify_url = 'http://localhost'
    n.data = 'data123'
    n.status = 0
    n.sender = Client.last
    n.save

    SendNotifyJob.perform_now(n)
    assert_equal 1, n.status
  end
=end
end
