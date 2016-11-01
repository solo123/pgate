require 'securerandom'
module Biz
  class PufubaoApi < BizBase
    attr_reader :err_code, :err_desc, :req_string
    def pay(payment)
      @err_code = '96'
      @err_desc = '系统功能尚未实现'
      pr = payment.build_pay_result
      pr.channel_name = 'pufubao.pay'
      pr.send_time = Time.now
      pr.uni_order_num = 'PL01' + ('%10d' % payment.id)

      #TODO: pufubao pay
      @req_string = gen_pay_string(payment)

      pr.send_code = @err_code
      pr.send_desc = @err_desc
      pr.save!
      payment.status = 7
      payment.save!
    end

    def gen_pay_string(payment)
      js = {
        service: 'WECHAT_WEBPAY',
        appid: payment.app_id,
        mch_id: 'pooul_id',
        device_info: payment.terminal_num,
        nonce_str: SecureRandom.hex(16),
        body: payment.order_title,
        attach: payment.attach_info,
        out_trade_no: payment.pay_result.uni_order_num,
        total_fee: payment.amount,
        spbill_create_ip: payment.remote_ip,
        notify_url: payment.notify_url,
        time_start: payment.order_time,
        time_expire: payment.order_expire_time,
        goods_tag: payment.goods_tag,
        trade_type: 'JSAPI',
        product_id: payment.product_id,
        limit_pay: payment.limit_pay,
        openid: payment.open_id
      }
      js.to_json
    end
  end
end
