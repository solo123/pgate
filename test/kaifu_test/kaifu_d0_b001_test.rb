require 'test_helper'

class KaifuD0B001Test < ActionDispatch::IntegrationTest
  test "send to server" do
    tmk = '9DB9095654D1FA7763F32E6B4E922140'
    js = {
      org_id: 'pooul_test',
      trans_type: 'P001',
      order_time: Time.now.strftime("%Y%m%d%H%M%S"),
      order_id: "TST" + Time.now.to_i.to_s,
      order_title: '购买测试001',
      pay_pass: '1',
      amount: '1000',
      fee: '33',
      card_no: '2345123412341234',
      card_holder_name: 'liangyihua',
      person_id_num: '450101198001010011',
      notify_url: 'http://112.74.184.236:8010/recv_notify',
      callback_url: 'http://www.pooul.cn'
    }
    tmk = '674CDA1B7D9866FA5398D2CE126C105B'
    mab = Biz::PubEncrypt.get_mab(js)
    js[:mac] = Biz::PubEncrypt.md5(mab + tmk)
    uri = URI('http://112.74.184.236:8008/payment')
    #uri = URI('http://localhost:8008/payment')
=begin
    resp = Net::HTTP.post_form(uri, data: js.to_json)

    puts '---------------------'
    puts 'resp: ' + resp.to_s
    puts 'body: ' + resp.body.to_s
=end
  end
  test "send D0 B001" do
    Biz::KaifuApi.stubs(:send_kaifu).returns({resp_code: '00', redirect_url: 'https://open.weixin.qq.com/mock'})
    js = {
      send_time: Time.now.strftime("%Y%m%d%H%M%S"),
      send_seq_id: "TST" + Time.now.to_i.to_s,
      trans_type: 'B001',
      organization_id: 'puerhanda',
      pay_pass: '1',
      trans_amt: '1000',
      fee: '33',
      card_no: '2345123412341234',
      name: 'liangyihua',
      id_num: '450101198001010011',
      body: "test-product01",
      notify_url: 'http://112.74.184.236:8010/recv_notify',
      callback_url: 'http://www.pooul.cn'
    }
    kf_js = Biz::KaifuApi.js_to_kaifu_format(js)
    kf_js[:mac] = Biz::KaifuApi.get_mac(kf_js, 'P001')

    ret_js = Biz::KaifuApi.send_kaifu(kf_js, 'P001')
    #puts '---------------------'
    #puts 'js: ' + kf_js.to_s
    #puts 'ret_js:' + ret_js.to_s
  end
end
