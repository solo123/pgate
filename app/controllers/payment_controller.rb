class PaymentController < ApplicationController
  def pay
    biz = Biz::GatewayPaymentBiz.new
    js = biz.check_required_params(params)
    if js
      render json: js
      return
    end

    payment = ClientPayment.new(params)
    js = payment.check_payment_fields
    payment.reload
    if js[:resp_code] == '00'
      biz = Biz::KaiFuApi.new
      biz.send_kaifu_payment(payment)
    end
    payment.reload
    render json: {resp_code: payment.resp_code, resp_desc: payment.resp_desc, redirect_url: payment.redirect_url}
  end

end
