class PaymentController < ApplicationController
  def pay
    begin
      para_js = JSON.parse(params[:data].force_encoding('UTF-8')).symbolize_keys
    rescue
      render json: {resp_code: '30', resp_desc: '数据格式错误'}
      return
    end

    biz = Biz::PaymentBiz.new
    js = biz.check_required_params(para_js)
    if js[:resp_code] != '00'
      render json: js
      return
    end

    payment = ClientPayment.new(para_js)
    payment.client = Client.find_by(org_id: para_js[:org_id])
    unless payment.client
      render json: {resp_code: '03', resp_desc: '无此商户:' + para_js[:org_id]}
      return
    end

    js = payment.check_payment_fields
    payment.save
    if js[:resp_code] != '00'
      render json: js
      return
    end

    biz = Biz::KaifuApi.new
    ret_js = biz.send_kaifu_payment(payment)
    payment.save if payment.changed?
    render json: ret_js
  end

end
