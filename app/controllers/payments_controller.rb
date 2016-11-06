class PaymentsController < ApplicationController
  def pay
    prv = ReqRecv.new
    prv.remote_ip = request.remote_ip
    prv.method = params[:method]
    prv.org_code = params[:org_code]
    prv.sign = params[:sign]
    prv.params = request.params.inspect
    prv.data = params[:data]
    prv.time_recv = Time.now
    prv.save

    biz = Biz::PaymentBiz.new
    biz.pay(prv)
    if biz.err_code == '00'
      js = {resp_code: '00'}
      pm = prv.payment.pay_result
      js[:pay_url] = pm.pay_url if pm.pay_url
      js[:barcode_url] = pm.barcode_url if pm.barcode_url
    else
      js = {resp_code: biz.err_code, resp_desc: biz.err_desc}
    end
    prv.resp_body = js.to_json
    prv.save
    render json: prv.resp_body
  end
=begin
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
=end
end
