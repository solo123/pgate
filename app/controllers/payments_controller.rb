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
    prv.resp_body = biz.gen_response_json
    prv.save
    render json: prv.resp_body
  end
end
