module Biz
  class PosEncrypt
    def e_mak(data, key_string)
      key = [key_string].pack('H*')
      key = key[0..15] + key[0..7]
      cipher = OpenSSL::Cipher.new 'des-ede'
      cipher.encrypt
      cipher.key = key
      cipher.padding = 0
      c1 = cipher.update(data)
      c2 = cipher.final
      c1
    end
    def e_mak_decrypt(data, key_string)
      key = [key_string].pack('H*')
      key = key[0..15] + key[0..7]
      cipher = OpenSSL::Cipher.new 'des-ede'
      cipher.decrypt
      cipher.key = key
      cipher.padding = 0
      c1 = cipher.update(data)
      c2 = cipher.final
      c1
    end

    def pos_mac(mab, key)
      result_block = xor_8(mab).unpack('H*')[0].upcase
      enc_block1 = e_mak(result_block[0..7], key)
      temp_block = xor_8(enc_block1 + result_block[8..15])
      enc_block2 = e_mak(temp_block, key).unpack('H*')[0]
      enc_block2[0..7].upcase
    end
    def xor_8(input_string)
      bs = input_string.bytes
      result_block = []
      (0..7).each do |i|
        result_block << cal_xor(bs, i)
      end
      result_block.pack('C*')
    end
    def cal_xor(arr, idx)
      len = arr.length
      i = idx
      r = 0
      while i < len do
        r = r ^ arr[i]
        i += 8
      end
      r
    end
  end
end
