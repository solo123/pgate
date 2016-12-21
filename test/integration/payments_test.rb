require 'test_helper'

class PaymentsTest < ActionDispatch::IntegrationTest
  setup do
  end

  test "P001 非法格式" do
    params = {
      org_code: 'pooul999',
      order_time: '20160915010001'
    }
    post pay_url,
      params: params,
      xhr: true,
      as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal '03', body['resp_code'], body['resp_desc']
  end
  test "P001 未注册商户" do
    params = {
      org_code: 'pooul9991',
      method: 'P001',
      data: '{"a":"1"}',
      sign: '111'
    }
    post pay_url, params: params
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal '02', body['resp_code'], body['resp_desc']
  end
  test 'P001 mac错' do
    params = {
      org_code: 'pooul1',
      method: 'P001',
      data: '{"a":"1"}',
      sign: '111'
    }
    post pay_url, params: params
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal '04', body['resp_code'], body['resp_desc']
  end
  test "org TMK" do
    org = Org.find_by(org_code: 'pooul1')
    assert_equal '1234567890abcdef', org.tmk
  end
  test 'Payment Duplicate' do
    data = {
      order_num: 'ORD-001-DUP',
      amount: '1000',
      order_title: 'test pufubao order 001 DUP'
    }

    params = {
      org_code: 'pooul1',
      method: 'TEST001',
      data: data.to_json,
      sign: Biz::PooulApi.get_mac(data, Org.find_by(org_code: 'pooul1').tmk)
    }
    post pay_url, params: params
    assert_response :success

    params[:method] = 'TEST001-DUP'
    post pay_url, params: params
    assert_response :success
    resp = JSON.parse(response.body)
    assert_equal '03', resp['resp_code'], resp['resp_desc']
  end

  test 'P001 成功提交' do
    stub_request(:post, "http://brcb.pufubao.net/gateway").
      to_return(status: 302, headers: { 'Location': 'https://open.weixin.qq.com/mock'})

    org = orgs(:one)
    js = {
      org_code: org.org_code,
      method: 'wechat.jsapi',
      order_time: '20160915010231',
      order_id: 'A20100001',
      order_title: '普尔支付-购买测试商品',
      pay_pass: '1',
      amount: '1000',
      fee: '33',
      card_no: '600012341000123',
      card_holder_name: ' 张三丰',
      person_id_num: '440101190001010011',
      notify_url: 'http://myapps.com/nitify',
      callback_url: 'http://mobileapp.com/callback'
    }
    params = {
      org_code: org.org_code,
      method: 'wechat.jsapi',
      data: js.to_json,
      sign: Biz::PooulApi.get_mac(js, org.tmk)
    }
    post pay_url, params: params
    assert_response :success
    j = JSON.parse(response.body)

    assert_equal '00', j['resp_code'], j.inspect
    assert_match /https:\/\/open.weixin.qq.com/, j['data']
  end
  test 'P001 成功提交 http302 redirect' do
    redirect_url = 'https://open.weixin.qq.com/mock'
    stub_request(:post, "http://brcb.pufubao.net/gateway").
      to_return(status: 302, headers: { 'Location': redirect_url})

    org = orgs(:one)
    js = {
      org_code: org.org_code,
      method: 'wechat.jsapi',
      order_time: '20160915010231',
      order_id: 'A20100001',
      order_title: '普尔支付-购买测试商品',
      pay_pass: '1',
      amount: '1000',
      fee: '33',
      card_no: '600012341000123',
      card_holder_name: ' 张三丰',
      person_id_num: '440101190001010011',
      notify_url: 'http://myapps.com/nitify',
      callback_url: 'http://mobileapp.com/callback'
    }
    params = {
      org_code: org.org_code,
      method: 'wechat.jsapi',
      data: js.to_json,
      sign: Biz::PooulApi.get_mac(js, org.tmk),
      redirect: 'Y'
    }
    post pay_url, params: params
    assert_response :redirect
    assert_redirected_to redirect_url
  end

  test "invalid format post" do
    post pay_url, params: "a=1&b=2"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal '03', body['resp_code'], body['resp_desc']
  end

  test "post form format" do
    params = {
      org_code: 'pooul1',
      method: 'P001',
      sign: '111',
      data: '{"a":"1"}'
    }
    post pay_url, params: params
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal '04', body['resp_code'], body['resp_desc']
  end

=begin
  test 'P001 手续费过低' do
    Biz::KaifuApi.stubs(:send_kaifu).returns({resp_code: '00', redirect_url: 'https://open.weixin.qq.com/mock'})
    params = {
      org_id: 'pooul',
      trans_type: 'P001',
      order_time: '20160915010231',
      order_id: 'A20100001',
      order_title: '普尔支付-购买测试商品',
      pay_pass: '1',
      amount: '1000',
      fee: '32',
      card_no: '600012341000123',
      card_holder_name: ' 张三丰',
      person_id_num: '440101190001010011',
      notify_url: 'http://myapps.com/nitify',
      callback_url: 'http://mobileapp.com/callback'
    }
    params[:mac] = Biz::PaymentBiz.get_client_mac(params)
    post pay_url, params: {data: params.to_json}
    assert_response :success
    j = JSON.parse(response.body)
    assert_equal '30', j['resp_code']
  end
=end
end
