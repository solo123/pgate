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
  test "pfb notify process basic-invalid" do
    rv = NotifyRecv.new
    rv.params = '{}'
    rv.sender = 'pfb'
    rv.method = 'notify'
    rv.status = 0
    id = Biz::PufubaoApi.process_notify(rv)
    assert_equal 0, id
  end
  test "pfb notify process basic" do
    rv = NotifyRecv.new
    rv.params = '{}'
    rv.sender = 'pfb'
    rv.method = 'notify'
    rv.ref = 'uni_001'
    rv.status = 0
    id = Biz::PufubaoApi.process_notify(rv)
    assert_equal 1, id
  end

  def prepare_notify
    rv = NotifyRecv.new
    rv.params = '{"appid"=>"wxf4bf6f1fc7a90d66", "bank_type"=>"SPDB_CREDIT", "fee_type"=>"CNY", "is_subscribe"=>"N", "mch_id"=>"C147937578318610572", "nonce_str"=>"b29c3592e6f6e357df24ff94cd34dbb1", "openid"=>"o0Od1wmnRuF4XuINcEdX3ykXKU50", "out_trade_no"=>"uni_001", "result_code"=>"SUCCESS", "return_code"=>"SUCCESS", "sign"=>"3813E12A395150068A4174B9AE8DC36C", "time_end"=>"20161128030830", "total_fee"=>1, "trade_type"=>"WECHAT_WEBPAY", "transaction_id"=>"O20161128030818776109088", "controller"=>"notify_recvs", "action"=>"notify", "sender"=>"pfb", "ref"=>"PL010000000049"}'
    rv.sender = 'pfb'
    rv.method = 'notify'
    rv.ref = 'uni_001'
    rv.status = 0
    rv.save
    rv
  end
  
  test "send_notify process" do
    rv = prepare_notify
    payment_id = Biz::PufubaoApi.process_notify(rv)
    assert_equal 1, payment_id
  end


end
