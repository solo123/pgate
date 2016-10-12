class PaymentController < ApplicationController
  def pay
    js = Biz::PaymentBiz.parse_data_json(params[:data])
    if js[:resp_code] != '00'
      render json: js
      return
    end

    payment = ClientPayment.new
    Biz::PaymentBiz.update_json(payment, js)
    unless payment.client = Client.find_by(org_id: js[:org_id])
      render json: {resp_code: '03', resp_desc: "无此客户:#{js[:org_id]}"}
      return
    end
    payment.remote_ip = request.headers['remote-addr']
    payment.uni_order_id = "#{payment.org_id}-#{payment.order_time[0..7]}-#{payment.order_id}"
    payment.save

    render json: Biz::PooulApi.payment(payment)
  end

end
