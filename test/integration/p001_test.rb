require 'test_helper'

class P001Test < ActionDispatch::IntegrationTest
  setup do
  end

  test "P001 非法格式" do
    params = {
      org_id: 'pooul999',
      order_time: '20160915010001'
    }
    post payment_url,
      params: params,
      xhr: true,
      as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal '30', body['resp_code']
  end
  test "P001 未注册商户" do
    params = {
      org_id: 'pooul9991',
      trans_type: 'P001',
      mac: '111'
    }
    post payment_url, params: {data: params.to_json}
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal '03', body['resp_code']
  end
  test 'P001 mac错' do
    params = {
      org_id: 'pooul',
      trans_type: 'P001',
      mac: '111'
    }
    post payment_url, params: {data: params.to_json}
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 'A0', body['resp_code']
  end
  test "client TMK" do
    client = Client.find_by(org_id: 'pooul')
    assert_equal '1234567890abcdef', client.tmk
  end

  test 'appconfig初始值' do
    assert_equal '1234567890abcdef', AppConfig.get('kaifu.user.d0.skey')
  end

  test 'P001 成功提交' do
    Biz::KaifuApi.stubs(:send_kaifu).returns({resp_code: '00', redirect_url: 'https://open.weixin.qq.com/mock'})
    params = {
      org_id: 'pooul',
      trans_type: 'P001',
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
    params[:mac] = Biz::PaymentBiz.get_client_mac(params)
    post payment_url, params: {data: params.to_json}
    assert_response :success
    j = JSON.parse(response.body)
    assert_equal '00', j['resp_code']
    assert_match /^https:\/\/open.weixin.qq.com/, j['redirect_url']
  end

  test "invalid format post" do
    post payment_url, params: "a=1&b=2"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal '30', body['resp_code']
  end

  test "post form format" do
    post payment_path, params: 'data={"org_id":"pooul","trans_type":"P001","mac":"abc"}'
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 'A0', body['resp_code']
  end

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
    post payment_url, params: {data: params.to_json}
    assert_response :success
    j = JSON.parse(response.body)
    assert_equal '30', j['resp_code']
  end

end
