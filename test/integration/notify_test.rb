require 'test_helper'

class NotifyTest < ActionDispatch::IntegrationTest
  test "post to notify url" do
    post notify_url(ref: 'order_num', sender: 'tst'), params: { a_fld: 'a field', b_fld: 'b field', data: 'data-txt' }
    assert_response :success

    r = NotifyRecv.find_by(data: 'data-txt')
    assert r
    assert_equal 'data-txt', r.data
    assert_equal 'notify', r.method
    assert_equal 'tst', r.sender
    assert_equal 'order_num', r.ref
  end
=begin
  test "send_notify" do
    #AppConfig.set('kaifu.host.notify', '127.0.0.2')
    rv = RecvPost.new
    rv.params = '{"appid"=>"wxf4bf6f1fc7a90d66", "bank_type"=>"SPDB_CREDIT", "fee_type"=>"CNY", "is_subscribe"=>"N", "mch_id"=>"C147937578318610572", "nonce_str"=>"b29c3592e6f6e357df24ff94cd34dbb1", "openid"=>"o0Od1wmnRuF4XuINcEdX3ykXKU50", "out_trade_no"=>"PL010000000049", "result_code"=>"SUCCESS", "return_code"=>"SUCCESS", "sign"=>"3813E12A395150068A4174B9AE8DC36C", "time_end"=>"20161128030830", "total_fee"=>1, "trade_type"=>"WECHAT_WEBPAY", "transaction_id"=>"O20161128030818776109088", "controller"=>"notify_recvs", "action"=>"notify", "sender"=>"pfb", "ref"=>"PL010000000049"}'

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
