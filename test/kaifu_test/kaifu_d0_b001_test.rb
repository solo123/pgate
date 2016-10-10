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
    #Biz::WebBiz.stubs(:post_data).returns()
    Biz::KaifuApi.stubs(:send_kaifu).returns({resp_code: '00', redirect_url: 'https://open.weixin.qq.com/mock'})
    k = kaifu_gateways(:one)
    js = Biz::KaifuApi.send_kaifu(k)
    assert_equal '00', js[:resp_code]
  end
end
