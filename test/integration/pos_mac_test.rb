require 'test_helper'

class PosMacTest < ActionDispatch::IntegrationTest
  test "e_mak加密算法" do
    data = ["BF3523B8E3845CB5300D97F976AF0A39"].pack('H*')
    key_str = "BA213DD564BBE85DDB62942364FBE85D"
    r = Biz::PosEncrypt.e_mak(data, key_str)
    r = r.unpack('H*')[0].upcase
    assert_equal '15C481BEC8A7155890694EBEAC00489F', r
  end
  test "e_mak_decrypt解密算法" do
    data = ["15C481BEC8A7155890694EBEAC00489F"].pack('H*')
    key_str = "BA213DD564BBE85DDB62942364FBE85D"
    r = Biz::PosEncrypt.e_mak_decrypt(data, key_str)
    r = r.unpack('H*')[0].upcase
    assert_equal 'BF3523B8E3845CB5300D97F976AF0A39', r
  end
=begin
  数据报文：
  0x 1234567890ABCDEFABCDEF1234567890   //$body
  MAK：2222222222222222
  Mac计算：
  M1 = 0x 1234567890ABCDEF
  M2 = 0x ABCDEF1234567890
  M1 Xor M2 结果: 0x B9F9B96AA4FDB57F
  扩展成16字节数据：0x 42394639423936414134464442353746
  MAK加密前半部分数据结果：0x 9FDE90A34CF73B2E
  加密结果与后半部分数据异或,结果：0x DEEAD6E70EC20C68
  MAK加密异或结果：0x E267B6E21913D339
  扩展成16字节数据：0x45323637423645323139313344333339
  Mac：E267B6E2
=end
  test "POS MAC加密算法" do
    mab = ['1234567890ABCDEFABCDEF1234567890'].pack('H*')
    key = '2222222222222222'
    mac = Biz::PosEncrypt.pos_mac(mab, key)
    assert_equal 'E267B6E2', mac
  end

  test "data xor in 8 bytes" do
    s = ['1234567890ABCDEFABCDEF1234567890'].pack('H*')
    assert_equal ['B9F9B96AA4FDB57F'].pack('H*'), Biz::PosEncrypt.xor_8(s)
  end

  test "encrypt_mak " do
    s = ['4239463942393641'].pack('H*')
    key = '2222222222222222'
    assert_equal ['9FDE90A34CF73B2E'].pack('H*'), Biz::PosEncrypt.e_mak(s, key)
  end


end
