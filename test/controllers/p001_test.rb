require 'test_helper'

class P001Test < ActionDispatch::IntegrationTest
  setup do
  end

  test "P001 非法格式" do
    l = Rails.logger
    l.level = :error

    params = {
      org_id: 'pooul999',
      order_time: '20160915010001'
    }
    post payment_url,
      params: params,
      xhr: true,
      as: :json
    assert_response :success
    l.info "response.body = " + response.body
    body = JSON.parse(response.body)

    assert_equal '30', body['resp_code']
  end
  test "P001 未注册商户" do
    l = Rails.logger

    params = {
      org_id: 'pooul999',
      trans_type: 'P001',
      mac: '111'
    }
    post payment_url,
      params: params,
      xhr: true,
      as: :json
    assert_response :success
    l.info "response.body = " + response.body
    body = JSON.parse(response.body)

    assert_equal '03', body['resp_code']
  end
  test 'P001 缺少字段' do
    l = Rails.logger
    l.level = :debug

    params = {
      org_id: 'pooul',
      trans_type: 'P001'

    }
    post payment_url,
      params: params,
      xhr: true,
      as: :json
    assert_response :success
    l.info "response.body = " + response.body
    body = JSON.parse(response.body)

    assert_equal '30', body['resp_code']

  end

  test 'P001 成功提交' do
    l = Rails.logger
    params = {
      org_id: 'pooul',
      trans_type: 'P001',
      order_time: '20160915010231',
      order_id: 'A20100001',
      order_title: '普尔支付-购买测试商品',
      pay_pass: '1',
      amount: '1000',
      fee: '6',
      card_no: '600012341000123',
      card_holder_name: ' 张三丰',
      person_id_num: '440101190001010011',
      notify_url: 'http://myapps.com/nitify',
      callback_url: 'http://mobileapp.com/callback',
      mac: '1234567890abcdef'
    }
    post payment_url,
      params: params,
      xhr: true,
      as: :json
    assert_response :success
    l.info "response.body = " + response.body
    body = JSON.parse(response.body)

    assert_equal '00', body['resp_code']
  end

end
