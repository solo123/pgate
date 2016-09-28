class PaymentController < ApplicationController
  def pay
    js = Biz::PaymentBiz.parse_data_json(params[:data])
    if js[:resp_code] != '00'
      render json: js
      return
    end

    payment = ClientPayment.new
    fields = payment.attributes.keys
    payment.attributes = js.reject{|k,v| !fields.member?(k.to_s) }
    payment.client = Client.find_by(org_id: js[:org_id])
    payment.save
    chk_js = payment.check_payment_fields
    if chk_js[:resp_code] != '00'
      render json: chk_js
      return
    end

    ret_js = Biz::KaifuApi.send_kaifu_payment(payment)
    payment.save if payment.changed?
    render json: ret_js
  end

end
