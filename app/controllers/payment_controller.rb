class PaymentController < ApplicationController
  def pay
    js = nil
    if %W(org_id trans_type mac).any? {|fld| params[fld].nil? }
      js = {resp_code: '30', resp_desc: '报文错，缺少org_id或trans_type或mac'}
    else
      client = Client.find_by(org_id: params[:org_id])
      if client.nil?
        js = {resp_code: '03', resp_desc: "无此商户: #{params[:org_id]}"}
      else
        case params[:trans_type]
        when 'P001'
          js = do_p001(client, params)
        else
          js = {resp_code: '12', resp_desc: "无此交易: #{params[:trans_type]}"}
        end
      end
    end
    render json: js
  end

  def do_p001(client, params)
    fields = %W(order_time order_id order_title pay_pass amount fee card_no card_holder_name person_id_num notify_url callback_url mac)
    if fields.any? { |fld| params[fld].nil? }
      return {resp_code: '30', resp_desc: '缺少必须的字段'}
    end

    return {resp_code: '00'}
  end
end
