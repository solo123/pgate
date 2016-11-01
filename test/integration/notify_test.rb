require 'test_helper'

class NotifyTest < ActionDispatch::IntegrationTest
  test "post to notify url" do
    post notify_url(sender: 'tst'), params: { a_fld: 'a field', b_fld: 'b field', data: 'data-txt' }
    assert_response :success

    r = NotifyRecv.find_by(data: 'data-txt')
    assert r
    assert_equal 'data-txt', r.data
    assert_equal 'notify', r.method
    assert_equal 'tst', r.sender
  end
=begin
  test "send_notify" do
    AppConfig.set('kaifu.host.notify', '127.0.0.2')
    rv = RecvPost.new
    rv.data = '{"fee":"12500","mac":"46434533","orgSendSeqId":"P1000087","organizationId":"puerhanda","payDesc":"支付成功","payResult":"00","transAmt":"400000"}'
    rv.remote_host = AppConfig.get('kaifu.host.notify')
    rv.save

    n = Biz::TransBiz.create_notify(rv)
    assert n
    assert_equal rv.id, n.sender_id
    assert_equal 'KaifuResult', n.sender_type
  end

  test "notify update KaifuGateway and ClientPayment" do
    AppConfig.set('kaifu.host.notify', '127.0.0.2')
    rv = RecvPost.new
    rv.data = '{"fee":"12500","mac":"46434533","orgSendSeqId":"P1000087","organizationId":"puerhanda","payDesc":"支付成功","payResult":"00","transAmt":"400000"}'
    rv.remote_host = AppConfig.get('kaifu.host.notify')
    rv.save

    n = Biz::TransBiz.create_notify(rv)
    assert n

    gw = KaifuGateway.find_by(send_seq_id: 'P1000087')
    assert gw

    assert_equal '00', gw.pay_code
    cp = gw.client_payment
    assert cp
    assert_equal '00', cp.pay_code
  end
=end

end
