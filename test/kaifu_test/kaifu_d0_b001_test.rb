require 'test_helper'

class KaifuD0B001Test < ActionDispatch::IntegrationTest
  test "send D0 B001" do
    Biz::KaifuApi.any_instance.stubs(:send_kaifu).returns({resp_code: '00', redirect_url: 'https://open.weixin.qq.com/mock'})
    tmk = '9DB9095654D1FA7763F32E6B4E922140'
    js = {
      send_time: "20160920155010",
      send_seq_id: "T0100002",
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
    biz = Biz::KaifuApi.new
    kf_js = biz.kaifu_api_format(js)
    kf_js[:mac] = biz.get_mac(kf_js, tmk)

    ret_js = biz.send_kaifu(kf_js)
  end
end
