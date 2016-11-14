require 'test_helper'

class AlipayTest < ActionDispatch::IntegrationTest
  test "pay to alipay correct" do
    pd = SentPost.new
    pd.method = 'alipay.trade.precreate'
    pd.resp_body = %{{"alipay_trade_precreate_response":{"code":"10000","msg":"Success","out_trade_no":"...","qr_code":"https:\/\/qr.alipay.com\/bax01268bjn1sppbfk200005"},"sign":"UHg0r/0EqLi9Ep4kH7rFPFoEueFwEfQH57Q4CopBY/Bz0CieUS3ti2v0Lo+FKREe/GDEpGoGmEHYhiERAArcSDvargPxRzwgtL8nnNuVT2RAHO0ijVlNoBMZeBrsEBqqXZv7nNgzZ8nwg/8bggXmKc2WvczEB3uxnNPhRH5YTvg="}}
    Biz::WebBiz.stubs(:post_data).returns(pd)

    rnd = rand(1000000).to_s.rjust(6, '0')
    ord_num = "ORD-#{rnd}"
    js = {
      order_num: ord_num,
      amount: '100',
      order_title: "test alipay order #{rnd}"
    }
    org = Org.find_by(org_code: 'pooul1')
    sign = Biz::PooulApi.get_mac(js, org.tmk)

    params = {
      org_code: 'pooul1',
      method: 'alipay.trade.precreate',
      sign: sign,
      data: js.to_json
    }
    post pay_url,
      params: params,
      xhr: true,
      as: :json
    assert_response :success

    body = Biz::PublicTools.parse_json(response.body)
    assert body
    assert_equal '00', body[:resp_code], body.to_s
    assert_equal ord_num, body[:order_num]
    assert body[:qr_code]
    assert body[:qr_code].start_with?('https://qr.alipay.com')
  end
  test "pay to alipay in-correct" do
    pd = SentPost.new
    pd.method = 'alipay.trade.precreate'
    pd.resp_body = %{{"alipay_trade_precreate_response":{"code":"40004","msg":"Business Failed","sub_code":"ACQ.INVALID_PARAMETER","sub_msg":"参数无效"},"sign":"VUvzsc2j3RftCJvllUH51KfBBbQ4KZIqRpgI9ftkkryQ5Sk7EDUSqVxaVdhoECONY/zhWi6zfTn9CefazeF/RQNHSf/FciqtOnt165aEWl2fCYNMJ5gkQwvyvzihgs6SRH/9ONPeSc6SQzI4DmHrR44ZNuNmN76pqtUw+L0/v3s="}}
    Biz::WebBiz.stubs(:post_data).returns(pd)

    rnd = rand(1000000).to_s.rjust(6, '0')
    ord_num = "ORD-#{rnd}"
    js = {
      order_num: ord_num,
      amount: '100',
      order_title: "test alipay order #{rnd}",
      nonce_str: '0x*(ddd)5x'
    }
    org = Org.find_by(org_code: 'pooul1')
    sign = Biz::PooulApi.get_mac(js, org.tmk)

    params = {
      org_code: 'pooul1',
      method: 'alipay.trade.precreate',
      sign: sign,
      data: js.to_json
    }
    post pay_url,
      params: params,
      xhr: true,
      as: :json
    assert_response :success

    body = Biz::PublicTools.parse_json(response.body)
    assert body
    assert_equal '20', body[:resp_code], body.to_s
  end

end
