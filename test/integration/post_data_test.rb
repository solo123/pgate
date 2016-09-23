require 'test_helper'

class PostDataTest < ActionDispatch::IntegrationTest
  test "post data" do
    data = '{"org_id":"xinzhongfu","trans_type":"P003","order_time":1474618529,"order_id":"OF201609231615293126","order_title":"\u963f\u91cc\u6751\u83c7D0\u6a21\u5f0f","pay_pass":"1","amount":100,"fee":"0.006500","card_no":"6123123456789012345","card_holder_name":"\u6797\u6b22","person_id_num":"350321123412341234","notify_url":"http:\/\/ali.alicungu.cn\/api.php\/wcpay\/notice","callback_url":"http:\/\/ali.alicungu.cn\/api.php\/wcpay\/callback_url","mac":"96EB1CDDC2DF43F5A95A9650A561D3A5"}"'
    post payment_url, params: {data: data}
    assert_response :success
    puts "data=" + response.body
    j = JSON.parse(response.body)
    assert_equal '00', j['resp_code']
  end
end
