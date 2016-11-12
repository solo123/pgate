module Biz
  class ChannelBiz < BizBase
    attr_reader :err_code, :err_desc, :resp_json
    FLDS_PAYMENT = %w(
      app_id open_id order_num order_time order_title
      attach_info amount fee remote_ip terminal_num
      method callback_url notify_url
    ).freeze

    def pay(payment)
      if payment.method.start_with? 'alipay.'
        biz = ZxAlipayBiz.new
      elsif payment.method.start_with? 'weixin.'
        biz = PufubaoApi.new
      end
      if biz
        biz.pay(payment)
        @resp_json = biz.gen_response_json
        @err_code = biz.err_code
        @err_desc = biz.err_desc
      else
        @err_code = '05'
        @err_desc = "请求类型错：method=[#{payment.method}]"
        @resp_json = {resp_code: @err_code, resp_desc: @err_desc}.to_json
      end
    end
  end
end
