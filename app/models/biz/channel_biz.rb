module Biz
  class ChannelBiz < BizBase
    attr_reader :err_code, :err_desc
    FLDS_PAYMENT = %w(
      app_id open_id order_num order_time order_title
      attach_info amount fee remote_ip terminal_num
      method callback_url notify_url
    ).freeze

    def send_channel(payment)
      # TODO: channel to pufubao
      biz = Biz::PufubaoApi.new
      biz.pay(payment)
      @err_code = biz.err_code
      @err_desc = biz.err_desc
    end
  end
end
