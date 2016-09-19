class PaymentController < ApplicationController
  def pay
    biz = Biz::GatewayPaymentBiz.new
    js = biz.check_required_params(params[:payment])
    if js[:resp_code] != '00'
      render json: js
      return
    end

    payment = ClientPayment.new(params[:payment])
    payment.client = Client.find_by(org_id: params[:org_id])
    payment.save
    #debugger
    js = payment.check_payment_fields
    payment.reload
    if js[:resp_code] == '00'
      biz = Biz::KaiFuApi.new
      biz.send_kaifu_payment(payment)
    end
    payment.reload
    render json: {resp_code: payment.resp_code, resp_desc: payment.resp_desc, redirect_url: payment.redirect_url}
  end

  def get_mac
    p = params[:payment].to_h
    mab = ''
    p.keys.sort.each do |k|
      mab << p[k]
    end
    if p['org_id']
      client = Client.find_by(org_id: p['org_id'])
      mab << Client.find_by(org_id: p['org_id']).tmk if client
    end
    render plain: Digest::MD5.hexdigest(mab) + "\n" + mab
  end

end
