require 'test_helper'

class HzybApiTest < ActionDispatch::IntegrationTest
  test "HZYB扫码支付" do
    stub_request(:post, "http://brcb.pufubao.net/gateway").
      to_return(status: 302, headers: { 'Location': 'https://open.weixin.qq.com/mock'})

    org = orgs(:one)
    js = {
      order_time: '20160915010231',
      order_id: 'A20100001',
      order_title: '普尔支付-购买测试商品',
      amount: '1000',
      notify_url: 'http://myapps.com/nitify',
      callback_url: 'http://mobileapp.com/callback'
    }
    params = {
      org_code: org.org_code,
      method: 'wechat.scan',
      data: js.to_json,
      sign: Biz::PooulApi.get_mac(js, org.tmk)
    }
    post pay_url, params: params
    assert_response :success
    j = JSON.parse(response.body)

    assert_equal '00', j['resp_code'], j.inspect
    assert_match /https:\/\/open.weixin.qq.com/, j['data']
  end

end
