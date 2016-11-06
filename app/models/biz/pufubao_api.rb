require 'securerandom'
module Biz
  class PufubaoApi < BizBase
    attr_reader :err_code, :err_desc, :req_data

    PUFUBAO_FIELDS_MAP = {
      appid: 'app_id',
      device_info: 'terminal_num',
      body: 'order_title',
      attach: 'attach_info',
      total_fee: 'amount',
      spbill_create_ip: 'remote_ip',
      time_start: 'order_time',
      openid: 'open_id',
      goods_tag: 'goods_tag'
    }.freeze

    PUFUBAO_PAY_URL = "http://brcb.pufubao.net/gateway".freeze
    PUFUBAO_ORG_NUM = "C147815927610610144".freeze
    PUFUBAO_KEY = "80ec3fa34fa04d8fa369d6170aaa55a2".freeze


    def pay(payment)
      pr = payment.build_pay_result
      pr.channel_name = 'pufubao'
      pr.send_time = Time.now
      pr.uni_order_num = 'PL01' + ('%10d' % payment.id)

      #TODO: pufubao pay
      #debugger
      @req_data = gen_pay_req_data(payment)
      ret = Biz::WebBiz.post_data('pufubao.pay', PUFUBAO_PAY_URL, @req_data, payment)
      if ret && ret.resp_body.start_with?('redirect_url')
        pr.pay_url = ret.resp_body[13, 200]
        pr.send_code = '00'
        payment.status = 1
      else
        pr.send_code = '97'
        if ret.resp_body && (ret_js = Biz::PublicTools.parse_json(ret.resp_body))
          pr.send_desc = "[#{ret_js[:return_code]}] #{ret_js[:return_msg]}"
        else
          pr.send_desc = ret.result_message
        end
        payment.status = 7
      end
      pr.save!
      payment.save!
      @err_code = pr.send_code.to_s
      @err_desc = pr.send_desc
    end

    def gen_pay_req_data(payment)
      js = Biz::PublicTools.gen_js(PUFUBAO_FIELDS_MAP, payment)
      js[:service_type] = 'WECHAT_WEBPAY'
      js[:mch_id] = PUFUBAO_ORG_NUM
      js[:nonce_str] = SecureRandom.hex(16)
      js[:notify_url] = AppConfig.get('pooul', 'notify_url')
      js[:trade_type] = 'JSAPI'
      js[:out_trade_no] = payment.pay_result.uni_order_num
      js[:sign] = self.class.get_mac(js, PUFUBAO_KEY)
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
