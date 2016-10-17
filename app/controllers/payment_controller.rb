class PaymentController < ApplicationController
  def pay
    log = BizLog.create(op_name: 'payment', op_message: params.inspect)
    js = Biz::PaymentBiz.parse_data_json(params[:data])
    if js[:resp_code] != '00'
      log.op_result = js.to_s
      log.save
      render json: js
      return
    end

    payment = ClientPayment.new
    Biz::PaymentBiz.update_json(payment, js)
    unless payment.client = Client.find_by(org_id: js[:org_id])
      js = {resp_code: '03', resp_desc: "无此客户:#{js[:org_id]}"}
      log.op_result = js.to_s
      log.save
      render json: js
      return
    end
    payment.remote_ip = request.remote_ip if payment.remote_ip
    payment.uni_order_id = "#{payment.org_id}-#{payment.order_time[0..7]}-#{payment.order_id}"
    payment.save

    js = Biz::PooulApi.payment(payment)
    log.op_result = js.to_s
    log.save
    render json: js
  end

end
