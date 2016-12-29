require 'securerandom'
module Biz
  class HzybApi < WeixinBiz
    HZYB_PAY_URL = "http://103.25.21.35:11111/gateway/qrcode".freeze
    HZYB_MCH_ID = '800010000020029'.freeze

    def pay(payment)
      @payment = payment
      pr = payment.build_pay_result
      pr.channel_name = 'hzyb'
      pr.send_time = Time.now
      pr.uni_order_num = 'PL01' + ('%010d' % payment.id)
      pr.channel_client_id = AppConfig.get("hzyb", "default_mch_id")

      case payment.method
      when 'wechat.scan'
        @req_data = gen_scan_pay_xml
        ret = post_xml('hzyb.pay', HZYB_PAY_URL + "/qrcodePay", @req_data, payment)
        reply_scan_xml(ret, pr)
      when 'wechat.micro'
        @req_data = gen_micro_pay_xml
        ret = post_xml('hzyb.pay', HZYB_PAY_URL + "/barcodePay", @req_data, payment)
        reply_micro_xml(ret, pr)
      when 'wechat.jsapi'
        # params = {
        #   'mercId': mch_id, # 商户编号
        #   'mercOrdNo': order_id, # 商户订单编号
        #   'merOrdDate': Time.now.strftime("%Y%m%d"), # 商户订单日期
        #   'Subject': '公众号测试订单', # 订单标题
        #   'payChannel': '1', # 支付渠道
        #   'txAmt': '0.01', # 金额
        #   'notifyUrl': notify_url #通知商户后台URL
        # }
        # @sign_str = ''
        # ['mercId','mercOrdNo','merOrdDate','txAmt','payChannel','notifyUrl'].each do |str_key|
        #   puts "#{str_key} = #{params[str_key.to_sym]}"
        #   @sign_str += "#{params[str_key.to_sym]}"
        # end
        # sn = sign1(@sign_str)
        # puts "=======签名后数据：#{sn}"
        # params['merchantSign'] = sn
        # puts params

        # resp = HTTParty.post(url, body: params)
        # puts resp
      else
        ret = nil
        pr.send_code = '03'
        pr.send_desc = "无此交易 [D0 - #{payment.method}]"
        payment.status = 7
      end
      pr.save!
      payment.save!
      @err_code = pr.send_code.to_s
      @err_desc = pr.send_desc
    end

    def gen_micro_pay_xml
      builder = Nokogiri::XML::Builder.new(:encoding => 'GBK') do |xml|
        xml.AIPG {
          xml.INFO {
            xml.TRX_CODE '100010'
            xml.VERSION '01'
            xml.REQ_SN @payment.pay_result.uni_order_num
            xml.SIGNED_MSG '[sign]'
          }
          xml.BODY {
            xml.TRANS_DETAIL {
              xml.QRCODE_CHANNEL '1'
              xml.MERCHANT_ID HZYB_MCH_ID
              xml.MER_ORD_DT @payment.order_day
              xml.TX_AMT (@payment.amount / 100.00).to_s
              xml.SUBJECT @payment.order_title
              xml.NOTIFY_URL AppConfig.get('pooul', 'notify_url') + '/hzyb/' + @payment.pay_result.uni_order_num
              xml.SCENE '1'
              xml.AUTH_CODE @payment.auth_code
            }
          }
        }
      end
      builder.to_xml
    end
    def reply_micro_xml(ret, pr)
      if ret
        xml = Nokogiri::XML(ret)
        if xml.xpath("/AIPG/INFO/REQ_SN").text == pr.uni_order_num &&
          xml.xpath("/AIPG/INFO/RET_CODE").text == '0000'
          pr.real_order_num = xml.xpath("/AIPG/BODY/TRANS_DETAIL/ORD_NO")
        else
          pr.send_code = "20"
          pr.send_desc = "通道方返回数据异常：#{xml.xpath('/AIPG/INFO/RET_CODE')} #{xml.xpath('/AIPG/INFO/ERR_MSG')}"
        end
      end
    end
    def gen_scan_pay_xml
      builder = Nokogiri::XML::Builder.new(:encoding => 'GBK') do |xml|
        xml.AIPG {
          xml.INFO {
            xml.TRX_CODE '100010'
            xml.VERSION '01'
            xml.REQ_SN @payment.pay_result.uni_order_num
            xml.SIGNED_MSG '[sign]'
          }
          xml.BODY {
            xml.TRANS_DETAIL {
              xml.QRCODE_CHANNEL '1'
              xml.MERCHANT_ID HZYB_MCH_ID
              xml.MER_ORD_DT @payment.order_day
              xml.TX_AMT (@payment.amount / 100.00).to_s
              xml.SUBJECT @payment.order_title
              xml.NOTIFY_URL AppConfig.get('pooul', 'notify_url') + '/hzyb/' + @payment.pay_result.uni_order_num
            }
          }
        }
      end
      builder.to_xml
    end
    def reply_scan_xml(ret, pr)
      if ret
        xml = Nokogiri::XML(ret)
        if xml.xpath("/AIPG/INFO/REQ_SN").text == pr.uni_order_num &&
          xml.xpath("/AIPG/INFO/RET_CODE").text == '0000'
          pr.qr_code = xml.xpath("/AIPG/BODY/TRANS_DETAIL/QRCODE")
          pr.real_order_num = xml.xpath("/AIPG/BODY/TRANS_DETAIL/ORD_NO")
        else
          pr.send_code = "20"
          pr.send_desc = "通道方返回数据异常：#{xml.xpath('/AIPG/INFO/RET_CODE')} #{xml.xpath('/AIPG/INFO/ERR_MSG')}"
        end
      end
    end

    def query(payment)
      req_js = {
        service_type: 'WECHAT_ORDERQUERY',
        mch_id: payment.org.pfb_mercht.mch_id,
        out_trade_no: payment.pay_result.uni_order_num,
        nonce_str: SecureRandom.hex(16),
      }
      req_js[:sign] = self.class.get_mac(req_js, payment.org.pfb_mercht.mch_key)
      pd = WebBiz.post_data('pufubao.query', PUFUBAO_PAY_URL, req_js, payment)
      if pd
        js = PublicTools.parse_json(pd.resp_body)
        if js && js[:return_code] == 'SUCCESS'
          @err_code = '00'
          if js[:result_code] == 'SUCCESS'
            pay_result = payment.pay_result
            pay_result.app_id = js[:appid]
            pay_result.open_id = js[:openid]
            pay_result.is_subscribe = js[:is_subscribe]
            pay_result.bank_type = js[:bank_type]
            pay_result.total_fee = js[:total_fee]
            pay_result.transaction_id = js[:transaction_id]
            pay_result.pay_time = js[:time_end]
            pay_result.pay_state = js[:trade_state]
            if js[:trade_state] == 'SUCCESS'
              pay_result.pay_code = '00'
            else
              pay_result.pay_code = js[:trade_state]
            end
            pay_result.pay_desc = js[:trade_state]
            payment.status = 8 if js[:trade_state] == 'SUCCESS'
            pay_result.save!
            payment.save!
          else
            @err_code = '20'
            @err_desc = "[#{js[:err_code]}] #{js[:err_code_des]}"
          end
        else
          @err_code = '20'
          @err_desc = '通道返回异常'
        end
      else
        @err_code = '21'
        @err_desc = '通道连接异常'
      end
    end

    def self.process_notify(notify_recv)
      return 0 unless notify_recv.status == 0 && notify_recv.ref && notify_recv.sender == 'pfb' && notify_recv.method == 'notify'

      js = eval(notify_recv.params)
      pay_result = PayResult.find_by(uni_order_num: notify_recv.ref)
      payment = pay_result.payment if pay_result
      if pay_result && payment
        if js['return_code'] == 'SUCCESS'
          if check_return_equal(payment, js)
            if js['result_code'] == 'SUCCESS'
              pay_result.app_id = js['appid']
              pay_result.open_id = js['openid']
              pay_result.is_subscribe = js['is_subscribe']
              pay_result.bank_type = js['bank_type']
              pay_result.total_fee = js['total_fee']
              pay_result.transaction_id = js['transaction_id']
              pay_result.pay_time = js['time_end']
              pay_result.pay_code = '00'
              pay_result.pay_desc = notify_recv.result_message = '支付成功'
              payment.status = 8
            else
              pay_result.pay_code = '70'
              pay_result.pay_desc = notify_recv.result_message = '支付失败'
            end
            notify_recv.status = 1
          else
            notify_recv.status = 7
            notify_recv.result_message = '回调信息与支付请求不匹配。'
          end
        else
          payment.status = 7
          pay_result.send_code = '70'
          pay_result.send_desc = js['return_msg']
        end
        notify_recv.save!
        pay_result.save!
        payment.save!
        payment.id
      else
        notify_recv.status = 7
        notify_recv.result_message = "pfb订单:[#{notify_recv.ref}]没找到！"
        notify_recv.save!
        0
      end
    end

    def self.check_return_equal(payment, js)
      pr = payment.pay_result
      pr.channel_client_id ||= js['mch_id']
      return pr.channel_client_id == js['mch_id'] && \
        pr.uni_order_num == js['out_trade_no']
    end

    def self.get_mab(js)
      mab = []
      js.keys.sort.each do |k|
        mab << "#{k}=#{js[k].to_s}" if k != :mac && k != :sign && js[k]
      end
      mab.join('&')
    end
    def self.md5(str)
      Digest::MD5.hexdigest(str)
    end
    def self.get_mac(js, key)
      md5(get_mab(js) + key).upcase
    end
    def sign(data)
      sign = nil
      begin
        socket = TCPSocket.open('127.0.0.1', 9001)
        socket.write("HzSign\0")
        socket.write(data)
        socket.write("\0")
        sign = socket.read
      rescue => e
        @err_code = ''
        @err_desc = "数据签名服务出错，#{e.message}"
      end
      sign
    end
    def verify(data, p7_key)
      pkcs7 = OpenSSL::PKCS7.new(Base64.decode64(p7_key))
      pkcs7.verify(pkcs7.certificates, OpenSSL::X509::Store.new, data, OpenSSL::PKCS7::NOVERIFY)
    end

    def sign_and_post_xml(method, url, xml, sender)
      pd = SentPost.new
      pd.method = method
      pd.sender = sender
      pd.post_url = url
      pd.post_data = data.to_s.truncate(2000, omission: '... (to long)')

      sign_txt = sign xml.gsub('[sign]', '')
      signed_txt = sign_txt.gsub('<SIGNED_MSG></SIGNED_MSG>', "<SIGNED_MSG>#{sign(sign_txt)}</SIGNED_MSG>")

      gzip = ActiveSupport::Gzip.compress(signed_txt)
      b64 = Base64.encode64(gzip)

      resp = HTTParty.post(url, body: b64, headers: {"Content-Type": "text/plain; charset=ISO-8859-1"})

      resp_zip = Base64.decode64(resp.body)
      resp_txt = ActiveSupport::Gzip.decompress(resp_zip).force_encoding('gbk')

      txt_no_sign = resp_txt.gsub(/<SIGNED_MSG>(.|\n)*<\/SIGNED_MSG>/, '<SIGNED_MSG></SIGNED_MSG>')
      txt_sign = resp_txt.match(/<SIGNED_MSG>((.|\n)*)<\/SIGNED_MSG>/)[1]
      txt_utf = txt_no_sign.encode('utf-8', 'gbk')
      ret_xml = nil
      if verify(txt_utf, txt_sign)
        ret_xml = txt_utf
      end
      pd.save!
      ret_xml
    end
    def set_payment_result(result_txt, pr)
      xml = Nokogiri::XML(result_txt)
      if xml.xpath("/AIPG/INFO/REQ_SN").text == pr.uni_order_num &&
        xml.xpath("/AIPG/INFO/RET_CODE").text == '0000'

      else
        @err_code = '70'
        @err_desc = "交易失败：#{xml.xpath("/AIPG/INFO/RET_CODE").text} #{xml.xpath("/AIPG/INFO/ERR_MSG")}"
      end

    end
=begin
micro pay
2.3.1 :002'> <AIPG>
2.3.1 :003'>     <INFO>
2.3.1 :004'>         <TRX_CODE>100010</TRX_CODE>
2.3.1 :005'>         <VERSION>01</VERSION>
2.3.1 :006'>         <DATA_TYPE>xml</DATA_TYPE>
2.3.1 :007'>         <REQ_SN>ORD-1482576879-001</REQ_SN>
2.3.1 :008'>         <RET_CODE>0000</RET_CODE>
2.3.1 :009'>         <ERR_MSG>交易成功</ERR_MSG>
2.3.1 :010'>         <SIGNED_MSG></SIGNED_MSG>
2.3.1 :011'>         <HZ_DT>20161224</HZ_DT>
2.3.1 :012'>     </INFO>
2.3.1 :013'>     <BODY>
2.3.1 :014'>         <TRANS_DETAIL>
2.3.1 :015'>             <QRCODE></QRCODE>
2.3.1 :016'>             <ORD_NO>201612200008095399</ORD_NO>
2.3.1 :017'>             <EXTEND1></EXTEND1>
2.3.1 :018'>             <EXTEND2></EXTEND2>
2.3.1 :019'>             <EXTEND3></EXTEND3>
2.3.1 :020'>         </TRANS_DETAIL>
2.3.1 :021'>     </BODY>
2.3.1 :022'> </AIPG>'
=end


  end
end
