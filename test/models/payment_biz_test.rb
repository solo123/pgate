require 'test_helper'

class PaymentBizTest < ActionDispatch::IntegrationTest
  test "pay test nil" do
    prv = ReqRecv.new
    prv.data = nil
    biz = Biz::PaymentBiz.new
    biz.pay(prv)
    assert_equal '03', biz.err_code, biz.err_desc
  end
  test "pay test org not exist" do
    prv = ReqRecv.new
    prv.org_code = 'pooul0'
    prv.method = 'md01'
    prv.sign = 'abc'
    prv.data = '{}'
    biz = Biz::PaymentBiz.new
    biz.pay(prv)
    assert_equal '02', biz.err_code, biz.err_desc
  end
  test "pay test mac wrong" do
    prv = ReqRecv.new
    prv.org_code = 'pooul1'
    prv.method = 'md01'
    prv.sign = 'abc'
    prv.data = '{"a":"1"}'
    biz = Biz::PaymentBiz.new
    biz.pay(prv)
    assert_equal '04', biz.err_code, biz.err_desc
  end
  test "pay to pufubao incorrect" do
    pd = SentPost.new
    pd.method = 'pufubao'
    pd.resp_body = '{"return_code":"SIGN000001","return_msg":"Sign error","sign":null}'
    Biz::WebBiz.stubs(:post_data).returns(pd)

    js = {
      order_num: 'ORD-001-982',
      amount: '1000'
    }
    biz = Biz::PaymentBiz.new
    prv = ReqRecv.new
    prv.org_code = 'pooul1'
    prv.method = 'weixin.jsapi'
    org = Org.find_by(org_code: 'pooul1')
    prv.sign = Biz::PooulApi.get_mac(js, org.tmk)
    prv.data = js.to_json

    biz.pay(prv)
    assert_equal '97', biz.err_code, biz.err_desc
    assert prv.payment
    assert_equal js[:order_num], prv.payment.order_num
    assert_equal 7, prv.payment.status
  end

  test "pay to pufubao correct" do
    pd = SentPost.new
    pd.method = 'pufubao'
    pd.resp_body = 'redirect_url:https://open.weixin.qq.com/connect/oauth2/authorize?appid=wx6f33ea382befa1e2&redirect_uri=http%3A%2F%2Fbrcb.pufubao.net%2Ftoken&response_type=code&scope=snsapi_base&state=O20161104120942312102699#wechat_redirect'
    Biz::WebBiz.stubs(:post_data).returns(pd)

    js = {
      order_num: 'ORD-001-982',
      amount: '1000',
      order_title: 'test pufubao order 001'
    }
    prv = ReqRecv.new
    prv.org_code = 'pooul1'
    prv.method = 'weixin.jsapi'
    org = Org.find_by(org_code: 'pooul1')
    prv.sign = Biz::PooulApi.get_mac(js, org.tmk)
    prv.data = js.to_json

    biz = Biz::PaymentBiz.new
    biz.pay(prv)
    assert_equal '00', biz.err_code, biz.err_desc
    assert prv.payment
    assert_equal js[:order_num], prv.payment.order_num
    assert_equal 1, prv.payment.status
    assert prv.payment.pay_result.pay_url.start_with?('https://open.weixin')
  end
end
