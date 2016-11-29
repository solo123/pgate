require 'test_helper'

class SendNotifyTest < ActionDispatch::IntegrationTest
  test "send notify connect timeout" do
    stub_request(:any, 'notify_url').to_raise(SocketError.new('Failed to connect...'))

    pm = Payment.new
    pm.org_id = 1
    pm.req_recv = ReqRecv.new
    pm.notify_url = 'http://notify_url'
    pr = pm.build_pay_result
    pm.save!

    sp = Biz::PaymentBiz.send_notify(pm)
    assert_equal 1, pr.notify_times
    puts sp.inspect
    puts sp.result_message
  end
  test "send notify success" do
    stub_request(:any, 'notify_url').to_return(
      body: 'SUCCESS', status: 200,
    )

    pm = Payment.new
    pm.org_id = 1
    pm.req_recv = ReqRecv.new
    pm.notify_url = 'http://notify_url'
    pr = pm.build_pay_result
    pm.save!

    sp = Biz::PaymentBiz.send_notify(pm)
    assert_equal 100, pr.notify_times
    puts sp.inspect
    puts sp.result_message
  end
end
