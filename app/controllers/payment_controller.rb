class PaymentController < ApplicationController
  def pay
    Rails.logger.level = 0

    biz = Biz::PaymentBiz.new
    begin
      para_js = JSON.parse(params[:data])
    rescue
      Rails.logger.info "数据格式错误：" + para_js.to_s
      render json: {resp_code: '30', resp_desc: '数据格式错误'}
      return
    end

    js = biz.check_required_params(para_js)
    if js[:resp_code] != '00'
      render json: js
      return
    end

    payment = ClientPayment.new(para_js)
    payment.client = Client.find_by(org_id: para_js['org_id'])
    payment.save
    #debugger
    js = payment.check_payment_fields
    payment.save
    if js[:resp_code] == '00'
      biz = Biz::KaifuApi.new
      biz.send_kaifu_payment(payment)
    end
    payment.reload
    render json: {resp_code: payment.resp_code, resp_desc: payment.resp_desc, redirect_url: payment.redirect_url}
  end

  def get_mac
    p = params[:data].to_h
    mab = ''
    p.keys.sort.each do |k|
      mab << p[k] if k != 'mac'
    end
    if p['org_id']
      client = Client.find_by(org_id: p['org_id'])
      mab << Client.find_by(org_id: p['org_id']).tmk if client
    end
    render plain: Digest::MD5.hexdigest(mab) + "\n" + mab
  end

end
