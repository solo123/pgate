require 'securerandom'
module Biz
  class PufubaoApi < WeixinBiz
    PUFUBAO_FIELDS_MAP = {
      appid: 'app_id',
      device_info: 'terminal_num',
      body: 'order_title',
      attach: 'attach_info',
      total_fee: 'amount',
      spbill_create_ip: 'remote_ip',
      time_start: 'order_time',
      openid: 'open_id',
      goods_tag: 'goods_tag',
      auth_code: 'auth_code'
    }.freeze
    PUFUBAO_PAY_URL = "http://brcb.pufubao.net/gateway".freeze

    def pay(payment)
      @payment = payment
      pr = payment.build_pay_result
      pr.channel_name = 'pufubao'
      pr.send_time = Time.now
      pr.uni_order_num = 'PL01' + ('%010d' % payment.id)
      unless payment.org.pfb_mercht
        @err_code = '05'
        @err_desc = "没有为此商户开通支付通道"
        return
      end

      #TODO: pufubao pay
      @req_data = gen_pay_req_data(payment)
      ret = WebBiz.post_data('pufubao.pay', PUFUBAO_PAY_URL, @req_data, payment)
      if ret && ret.resp_body.start_with?('redirect_url')
        pr.pay_url = ret.resp_body[13, 200]
        pr.send_code = '00'
        payment.status = 1
      else
        if ret.resp_body && (ret_js = PublicTools.parse_json(ret.resp_body))
          if ret_js[:return_code] == 'SUCCESS'
            pr.send_code = '00'
            payment.status = 1
            case payment.method
            when 'wechat.scan'
              pr.qr_code = ret_js[:code_url]
              pr.real_order_num = ret_js[:prepay_id]
            when 'wechat.micro'
              if ret_js[:result_code] == 'SUCCESS'
                pr.open_id = ret_js[:openid]
                pr.is_subscribe = ret_js[:is_subscribe]
                pr.bank_type = ret_js[:bank_type]
                pr.total_fee = ret_js[:total_fee]
                pr.transaction_id = ret_js[:transaction_id]
                pr.pay_time = ret_js[:time_end]
                pr.need_query = ret_js[:need_query]
                pr.pay_code = '00'
                pr.pay_desc = '支付成功'
                payment.status = 8
              else
                pr.send_code = '70'
                pr.send_desc = "交易失败 [#{ret_js[:err_code]}] #{ret_js[:err_code_des]}"
                payment.status = 7
              end
            end
          else
            pr.send_code = '97'
            pr.send_desc = "[#{ret_js[:return_code]}] #{ret_js[:return_msg]}"
            payment.status = 7
          end
        else
          pr.send_code = '97'
          pr.send_desc = ret.result_message
          payment.status = 7
        end
      end
      pr.save!
      payment.save!
      @err_code = pr.send_code.to_s
      @err_desc = pr.send_desc
    end
    def gen_response_json
      if @err_code == '00'
        if @payment.method == 'wechat.scan'
          {
            resp_code: '00', org_code: @payment.org.org_code,
            order_num: @payment.order_num,
            prepay_id: @payment.pay_result.real_order_num,
            qr_code: @payment.pay_result.qr_code
          }.to_json
        elsif @payment.method == 'wechat.micro'
          {
            resp_code: '00', org_code: @payment.org.org_code,
            order_num: @payment.order_num,
            pay_code: @payment.pay_result.pay_code,
            pay_desc: @payment.pay_result.pay_desc,
            open_id: @payment.pay_result.open_id,
            is_subscribe: @payment.pay_result.is_subscribe,
            bank_type: @payment.pay_result.bank_type,
            need_query: @payment.pay_result.need_query,
            pay_time: @payment.pay_result.pay_time,
          }.to_json
        else
          {
            resp_code: '00', org_code: @payment.org.org_code,
            order_num: @payment.order_num,
            pay_url: @payment.pay_result.pay_url
          }.to_json
        end
      else
        {resp_code: @err_code, resp_desc: @err_desc}.to_json
      end
    end


    def gen_pay_req_data(payment)
      js = PublicTools.gen_js(PUFUBAO_FIELDS_MAP, payment)
      case payment.method
      when 'wechat.jsapi'
        if payment.app_id && payment.open_id
          js[:service_type] = 'WECHAT_UNIFIEDORDER'
        else
          js[:service_type] = 'WECHAT_WEBPAY'
        end
      when 'wechat.scan'
        js[:service_type] = 'WECHAT_SCANNED'
      when 'wechat.micro'
        js[:service_type] = 'WECHAT_MICRO'
      else
        js[:service_type] = 'WECHAT_WEBPAY'
      end
      js[:trade_type] = 'JSAPI'
      js[:mch_id] = payment.org.pfb_mercht.mch_id
      js[:nonce_str] = SecureRandom.hex(16)
      js[:notify_url] = AppConfig.get('pooul', 'notify_url')
      js[:out_trade_no] = payment.pay_result.uni_order_num
      js[:sign] = self.class.get_mac(js, payment.org.pfb_mercht.mch_key)
      js
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

  end
end
