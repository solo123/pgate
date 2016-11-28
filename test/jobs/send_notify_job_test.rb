require 'test_helper'

class SendNotifyJobTest < ActiveJob::TestCase
  test 'SendNotifyJob running' do
    SendNotifyJob.perform_now(1)
    p = Payment.find(1)
    assert_equal 0, p.status
  end

  test 'SendNotifyJob retry...' do
    return
    SendNotifyJob.perform_now(1)
    p = Payment.find(1)
    assert_equal 1, n.status
  end
end
