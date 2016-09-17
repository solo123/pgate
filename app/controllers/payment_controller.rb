class PaymentController < ApplicationController
  def pay

    js = nil
    if %W(org_id trans_type mac).any? {|fld| params[fld].nil? }
      js = {resp_code: '30', resp_desc: '报文错，缺少org_id或trans_type或mac'}
    else
      client = Client.find_by(org_id: params[:org_id])
      if client.nil?
        js = {resp_code: '03', resp_desc: "无此商户: #{params[:org_id]}", status: 7}
      else
        case params[:trans_type]
        when 'P001'
          js = do_p001(client, params)
        else
          js = {resp_code: '12', resp_desc: "无此交易: #{params[:trans_type]}", status: 7}
        end
      end
    end
    render json: js
  end

  def do_p001(client, params)
    fields = %W(order_time order_id order_title pay_pass amount fee card_no card_holder_name person_id_num notify_url callback_url mac)
    if fields.any? { |fld| params[fld].nil? }
      return {resp_code: '30', resp_desc: '缺少必须的字段', status: 7}
    end
    payment = ClientPayment.new(params)
    payment.client = client
    if payment.fee == 0
      payment.fee = payment.amount * client.d0_min_percent / 1000000 + client.d0_min_fee
    end
    payment.save

    biz = Biz::KaifuApi.new
    b001_gw = biz.create_b001(payment)
    biz.sent_to_kaifu(b001_gw)

    return {resp_code: b001_gw.resp_code, resp_desc: b001_gw.resp_desc, status: b001_gw.status, finish_time: Time.now}
  end
end
