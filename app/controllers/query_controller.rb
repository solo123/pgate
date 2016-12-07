class QueryController < ApplicationController
  def qry
    prv = ReqRecv.new
    prv.remote_ip = request.remote_ip
    prv.method = params[:method] || 'query'
    prv.org_code = params[:org_code]
    prv.sign = params[:sign]
    prv.params = request.params.inspect
    prv.data = params[:data]
    prv.time_recv = Time.current
    prv.save

    biz = Biz::PaymentBiz.new
    biz.query(prv)
    prv.resp_body = biz.gen_query_response
    prv.save
    render json: prv.resp_body
  end



  def tt
    js = Biz::PaymentBiz.parse_data_json(params[:data])
    if js[:resp_code] != '00'
      log.op_result = js.to_json
      log.save!
      render json: js
      return
    end

    required_fields = [:order_time, :order_id]
    if !(miss_flds = required_fields.select{|f| js[f].nil? }).empty?
      js = {resp_code: '30', resp_desc: '报文错，缺少字段：' + miss_flds.join(', ')}
      log.op_result = js.to_json
      log.save!
      render json: js
      return
    end

    js = Biz::PaymentBiz.pay_query(js[:org_id], js[:order_time], js[:order_id])
    log.op_result = js.to_json
    log.save!
    render json: js
  end

end
