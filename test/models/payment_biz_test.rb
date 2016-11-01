require 'test_helper'

class PaymentBizTest < ActionDispatch::IntegrationTest
  test "pay test nil" do
    prv = ReqRecv.new
    prv.data = nil
    biz = Biz::PaymentBiz.new
    biz.pay(prv)
    assert_equal '30', biz.err_code, "非法格式"
  end
  test "pay test org not exist" do
    prv = ReqRecv.new
    prv.data = '{"org_code":"pooul0","method":"md01","sign":"abd"}'
    biz = Biz::PaymentBiz.new
    biz.pay(prv)
    assert_equal '03', biz.err_code, '商户不存在'
  end
  test "pay test mac wrong" do
    prv = ReqRecv.new
    prv.data = '{"org_code":"pooul1","method":"md01","sign":"abd"}'
    biz = Biz::PaymentBiz.new
    biz.pay(prv)
    assert_equal 'A0', biz.err_code, 'mac错'
  end
  test "pay correct with server return 96" do
    #Biz::PufubaoApi.any_instance.stubs(:pay).returns(true)
    #Biz::PufubaoApi.any_instance.stubs(:err_code).returns('96')

    js = {
      org_code: 'pooul1',
      method: 'jsapi',
      order_num: 'ORD-001-982',
      amount: '1000'
    }
    org = Org.find_by(org_code: 'pooul1')
    js[:sign] = Biz::PublicTools.get_mac(js, org.tmk)
    biz = Biz::PaymentBiz.new
    prv = ReqRecv.new
    prv.data = js.to_json
    biz.pay(prv)
    assert_equal '96', biz.err_code
    assert prv.payment
    assert_equal js[:order_num], prv.payment.order_num
    assert_equal 7, prv.payment.status
  end
end
