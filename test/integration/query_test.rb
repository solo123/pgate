require 'test_helper'

class QueryTest < ActionDispatch::IntegrationTest
  test "query request basic" do
    post query_url, params: { abc: 'a field', data: 'data-txt', def: 'abc' }
    assert_response :success

    r = ReqRecv.find_by(data: 'data-txt')
    assert r
    assert_equal 'data-txt', r.data
    assert_equal 'query', r.method
    js = JSON.parse(response.body)
    assert_equal '03', js['resp_code'], js.inspect
  end
  test "query miss required fields" do
    org = orgs(:one)
    post query_url, params: { org_code: org.org_code, data: 'data-txt', sign: 'abc' }
    assert_response :success

    r = ReqRecv.find_by(data: 'data-txt')
    assert r
    assert_equal 'data-txt', r.data
    assert_equal 'query', r.method
    js = JSON.parse(response.body)
    assert_equal '03', js['resp_code'], js.inspect
  end
  test "query request order_not_found" do
    org = orgs(:one)
    js = {
      order_num: 'order_not_exist'
    }
    sign = Biz::PooulApi.get_mac(js, org.tmk)
    post query_url, params: { org_code: org.org_code, data: js.to_json, sign: sign  }
    assert_response :success
    resp = response.body
    r_js = JSON.parse resp
    assert_equal '03', r_js['resp_code'], r_js.inspect
  end
  test "query with not send payment" do
    stub_request(:any, "http://brcb.pufubao.net/gateway").to_return(status: 200, body: "ERROR")
    pm = payments(:one)
    org = pm.org
    js = {
      order_day: pm.order_time,
      order_num: pm.order_num,
    }
    sign = Biz::PooulApi.get_mac(js, org.tmk)

    post query_url, params: { org_code: org.org_code, data: js.to_json, sign: sign  }
    assert_response :success
    resp = response.body
    r_js = eval(resp)
    assert_equal '00', r_js[:resp_code], r_js.inspect
    data_js = JSON.parse(r_js[:data])
    assert_equal '70', data_js['pay_code'], data_js.inspect
    pm = Payment.find_by(order_num: pm.order_num)
    assert_equal 7, pm.status
  end
  test "query with paid payment" do
    stub_request(:any, "http://brcb.pufubao.net/gateway").to_return(status: 200, body: "ERROR")
    pm = payments(:three)
    org = pm.org
    js = {
      order_day: pm.order_time,
      order_num: pm.order_num,
    }
    sign = Biz::PooulApi.get_mac(js, org.tmk)

    post query_url, params: { org_code: org.org_code, data: js.to_json, sign: sign  }
    assert_response :success
    resp = response.body
    r_js = eval(resp)
    assert_equal '00', r_js[:resp_code], r_js.inspect
    data_js = JSON.parse(r_js[:data])
    assert_equal '00', data_js['pay_code'], data_js.inspect
    pm = Payment.find_by(order_num: pm.order_num)
    assert_equal 8, pm.status
  end
  test "query with cancel payment" do
    stub_request(:any, "http://brcb.pufubao.net/gateway").to_return(status: 200, body: "ERROR")
    pm = payments(:four)
    org = pm.org
    js = {
      order_day: pm.order_time,
      order_num: pm.order_num,
    }
    sign = Biz::PooulApi.get_mac(js, org.tmk)

    post query_url, params: { org_code: org.org_code, data: js.to_json, sign: sign  }
    assert_response :success
    resp = response.body
    r_js = eval(resp)
    assert_equal '00', r_js[:resp_code], r_js.inspect
    data_js = JSON.parse(r_js[:data])
    assert_equal '70', data_js['pay_code'], data_js.inspect
    pm = Payment.find_by(order_num: pm.order_num)
    assert_equal 7, pm.status
  end

  test "query request success" do
    stub_request(:any, "http://brcb.pufubao.net/gateway").to_return(status: 200, body: "{\"appid\":\"wxf4bf6f1fc7a90d66\",\"bank_type\":\"ICBC_DEBIT\",\"fee_type\":\"CNY\",\"is_subscribe\":\"N\",\"mch_id\":\"C148031229801910038\",\"nonce_str\":\"24f85bf195b1ed4a477fd0ebf24241f5\",\"openid\":\"o0Od1wj_NRPk8Frd0i_AvElRooQM\",\"out_trade_no\":\"PL010000000176\",\"result_code\":\"SUCCESS\",\"return_code\":\"SUCCESS\",\"sign\":\"5A381367D649BD175071573D7C7D2AA4\",\"time_end\":\"20161208005244\",\"total_fee\":5000,\"trade_type\":\"WECHAT_SCANNED\",\"transaction_id\":\"O20161208005155107100427\",\"trade_state\":\"USERPAYING\"}")
    pm = payments(:two)
    org = pm.org
    js = {
      order_day: pm.order_time,
      order_num: pm.order_num,
    }
    sign = Biz::PooulApi.get_mac(js, org.tmk)

    post query_url, params: { org_code: org.org_code, data: js.to_json, sign: sign  }
    assert_response :success
    resp = response.body
    r_js = eval(resp)
    assert_equal '00', r_js[:resp_code], r_js.inspect
    data_js = JSON.parse(r_js[:data])
    assert_equal 'USERPAYING', data_js['pay_state'], data_js.inspect
    pm = Payment.find_by(order_num: pm.order_num)
    assert_equal 1, pm.status
  end
  test "query request success and update payment_status" do
    stub_request(:any, "http://brcb.pufubao.net/gateway").to_return(status: 200, body: "{\"appid\":\"wxf4bf6f1fc7a90d66\",\"bank_type\":\"ICBC_DEBIT\",\"fee_type\":\"CNY\",\"is_subscribe\":\"N\",\"mch_id\":\"C148031229801910038\",\"nonce_str\":\"24f85bf195b1ed4a477fd0ebf24241f5\",\"openid\":\"o0Od1wj_NRPk8Frd0i_AvElRooQM\",\"out_trade_no\":\"PL010000000176\",\"result_code\":\"SUCCESS\",\"return_code\":\"SUCCESS\",\"sign\":\"5A381367D649BD175071573D7C7D2AA4\",\"time_end\":\"20161208005244\",\"total_fee\":5000,\"trade_type\":\"WECHAT_SCANNED\",\"transaction_id\":\"O20161208005155107100427\",\"trade_state\":\"SUCCESS\"}")
    pm = payments(:two)
    org = pm.org
    js = {
      order_day: pm.order_time,
      order_num: pm.order_num,
    }
    sign = Biz::PooulApi.get_mac(js, org.tmk)

    post query_url, params: { org_code: org.org_code, data: js.to_json, sign: sign  }
    assert_response :success
    resp = response.body
    r_js = eval(resp)
    assert_equal '00', r_js[:resp_code], r_js.inspect
    data_js = JSON.parse(r_js[:data])
    assert_equal 'SUCCESS', data_js['pay_state'], data_js.inspect
    pm = Payment.find_by(order_num: pm.order_num)
    assert_equal 8, pm.status
  end
end
