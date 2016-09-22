require 'test_helper'

class KaifuMacTest < ActionDispatch::IntegrationTest
  test "凯富MAC算法" do
    mab = "20160913201609132016091320160913"
    key = "AB73C9416D41E936E82AAC11053BCEDD"
    biz = Biz::KaifuApi.new
    mac = biz.kaifu_mac(mab, key)
    assert_equal '33303237', mac
  end
  test "凯富MAC算法-带中文" do
    mab = "普尔测试 - 测试商品http://a.pooulcloud.cn/test_pages/pay622588655645571333450303197005030016梁益华http://112.74.184.236:8010/recv_notifypuerhanda1P1000065201609221159161000B001"
    key = "D83209FCB0017CC2C67FD0C6373D6475"
    biz = Biz::KaifuApi.new
    mac = biz.kaifu_mac(mab, key)
    assert_equal '35373542', mac
  end
end
