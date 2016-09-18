class PaymentController < ApplicationController
  def pay
    biz = Biz::GatewayPaymentBiz.new
    js = biz.check_required_params(params)
    if js
      render json: js
      return
    end

    payment = ClientPayment.new(params)
    js = payment.check_payment_fields
    payment.reload
    if js[:resp_code] == '00'
      biz = Biz::KaiFuApi.new
      biz.send_kaifu_payment(payment)
    end
    payment.reload
    render json: {resp_code: payment.resp_code, resp_desc: payment.resp_desc, redirect_url: payment.redirect_url}
  end

  def validate_params(params)
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
    mab = ''
    fields.sort.each do |fld|
      if fld != 'mac'
        mab << params[fld]
      end
    end
    mac = Digest::MD5.hexdigest(mab + client.tmk).upcase
    if payment.mac.upcase != mac
      js = {resp_code: 'A0', resp_code: '检验mac错', status: 7}
      payment.update(js)
      return js
    end

    biz = Biz::KaifuApi.new
    b001_gw = biz.create_b001(payment)
    biz.sent_to_kaifu(b001_gw)

    return {resp_code: b001_gw.resp_code, resp_desc: b001_gw.resp_desc, status: b001_gw.status, finish_time: Time.now}
  end
end
