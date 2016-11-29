require 'test_helper'

class SendNotifyJobTest < ActiveJob::TestCase
  test 'SendNotifyJob running' do
    stub_request(:post, "http://localhost:8008/callback/test").to_return(
      :status => 200, :body => "", :headers => {}
    )
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
