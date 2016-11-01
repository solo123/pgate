class QueryController < ApplicationController
  def qry
    log = BizLog.create(op_name: 'query', op_message: params.inspect)
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
