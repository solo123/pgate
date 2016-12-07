module Biz
  class PaymentBiz < BizBase
    attr_reader :err_code, :err_desc, :resp_json
    FLDS_PAYMENT = %w(
      app_id open_id order_num order_time order_title
      attach_info amount fee remote_ip terminal_num
      callback_url notify_url auth_code
    ).freeze

    #params: prv = req_recv
    def pay(prv)
      @err_code = '00'
      @err_desc = ''

      required_fields = [:org_code, :method, :sign, :data]
      miss_flds = required_fields.select{|f| prv[f].nil? }
      unless miss_flds.empty?
        @err_code = '03'
        @err_desc = '报文错，缺少字段：' + miss_flds.join(', ')
        return nil
      end

      @org = Org.valid_status.find_by(org_code: prv.org_code)
      if @org.nil?
        @err_code = '02'
        @err_desc = "无此商户: #{prv.org_code}"
        return nil
      end

      js_recv = parse_data_json(prv.data)
      unless js_recv
        @err_code = '03'
        @err_desc = "业务数据为空: data=[#{prv.data}]"
        return nil
      end

      chk_sign = PooulApi.get_mac(js_recv, @org.tmk)
      if prv.sign != chk_sign
        @err_code = '04'
        @err_desc = "sign检验错"
        return nil
      end

      o_day = Time.current.strftime("%Y%m%d")
      if Payment.find_by(org: @org, order_day: o_day, order_num: js_recv[:order_num])
        @err_code = '03'
        @err_desc = "order_num当日重复: [#{js_recv[:order_num]}]"
        return nil
      end

      payment = prv.build_payment
      payment.org = @org
      payment.method = prv.method
      payment.order_day = o_day
      Biz::PublicTools.update_fields_json(FLDS_PAYMENT, payment, js_recv)
      payment.save!

      biz = Biz::ChannelBiz.new
      biz.pay(payment)
      @err_code = biz.err_code
      @err_desc = biz.err_desc
      @resp_json = biz.resp_json
    end
    def gen_response_json
      if @err_code == '00'
        @resp_json
      else
        {resp_code: @err_code, resp_desc: @err_desc}.to_json
      end
    end

    #params: prv = req_recv
    def query(prv)
      @err_code = '00'
      @err_desc = ''

      required_fields = [:org_code, :sign, :data]
      miss_flds = required_fields.select{|f| prv[f].nil? }
      unless miss_flds.empty?
        @err_code = '03'
        @err_desc = '报文错，缺少字段：' + miss_flds.join(', ')
        return nil
      end

      @org = Org.valid_status.find_by(org_code: prv.org_code)
      if @org.nil?
        @err_code = '02'
        @err_desc = "无此商户: #{prv.org_code}"
        return nil
      end

      js_recv = parse_data_json(prv.data)
      unless js_recv
        @err_code = '03'
        @err_desc = "业务数据为空: data=[#{prv.data}]"
        return nil
      end

      chk_sign = PooulApi.get_mac(js_recv, @org.tmk)
      if prv.sign != chk_sign
        @err_code = '04'
        @err_desc = "sign检验错"
        return nil
      end

      if payment = Payment.find_by(org: @org, order_day: order_day, order_num: order_num)
        if payment.status >= 7
          #直接返回交易结果
          @err_code = '00'
          @resp_json = create_pay_result(payment)
        else
          #查询渠道后返回交易结果
          biz = ChannelBiz.new
          biz.query(payment)
          @err_code = biz.err_code
          @err_desc = biz.err_desc
          if @err_code == '00'
            @resp_json = create_pay_result(payment)
          end
        end
      else
        @err_code = '90'
        @err_desc = "订单[#{order_day}-#{order_num}]没有找到"
        @resp_json = nil
      end
    end
    def gen_query_response
      #TODO: 未修改
      if @err_code == '00'
        @resp_json
      else
        {resp_code: @err_code, resp_desc: @err_desc}.to_json
      end
    end


    def parse_data_json(data)
      js = nil
      if data.nil? || data.empty?
        @err_code = '30'
        @err_desc = '报文为空'
        return nil
      end
      if !data.match( /{.+}/ )
        @err_code = '30'
        @err_desc = '数据格式错误'
        return nil
      end
      begin
        js = JSON.parse(data.force_encoding('UTF-8')).symbolize_keys
      rescue => e
        @err_code = '30'
        @err_desc = '数据JSON格式解析错误：' + e.message
        return nil
      end

      js
    end


    def self.create_pay_result(pm)
      notify_time = Time.now
      js = {
        org_code: pm.org.org_code,
        method: pm.method,
        order_num: pm.order_num,
        order_time: pm.order_time,
        amount: pm.amount,
        attach_info: pm.attach_info,
        send_code: pm.pay_result.send_code,
        send_desc: pm.pay_result.send_desc,
        pay_code: pm.pay_result.pay_code,
        pay_desc: pm.pay_result.pay_desc,
        notify_time: notify_time.strftime("%Y%m%d%H%M%S"),
      }.select { |_, value| !value.nil? }
      js[:pay_time] = pm.pay_result.pay_time.strftime("%Y%m%d%H%M%S") if pm.pay_result.pay_time

      sign = Biz::PooulApi.get_mac(js, pm.org.tmk)
      {data: js.to_json, sign: sign}
    end
    #params pm = payment
    def self.send_notify(pm)
      sp = Biz::WebBiz.post_data('notify', pm.notify_url, create_pay_result(pm), pm)
      if pm.pay_result.notify_times
        pm.pay_result.notify_times += 1
      else
        pm.pay_result.notify_times = 1
      end
      pm.pay_result.last_notify_at = Time.now
      pm.pay_result.notify_times = 100 if sp.resp_body =~ /(true)|(ok)|(success)|(SUCCESS)/
      pm.pay_result.save!
      pm.save!
      sp
    end
=begin
    def self.pay_query(org_id, order_time, order_id)
      uid = "#{org_id}-#{order_time[0..7]}-#{order_id}"
      if cp = ClientPayment.find_by(uni_order_id: uid)
        fields = [:org_id, :trans_type, :order_time, :order_id, :order_title, :img_url, :amount, :fee, :card_no, :card_holder_name, :person_id_num, :notify_url, :callback_url, :mac, :created_at, :redirect_url, :pay_code, :pay_desc, :t0_code, :t0_desc, :remote_ip, :uni_order_id, :notify_times, :notify_status, :last_notify, :attach_info, :sp_udid, :pay_time, :close_time, :refund_id]
        js = db_2_json(fields, cp)
        js['resp_code'] = '00'
        js['mac'] = Biz::PubEncrypt.md5_mac(js, cp.client.tmk)
        js
      else
        {resp_code: '12', resp_desc: "无此交易: #{uid}"}
      end

    end

    def self.db_2_json(fields, db)
      js = {}
      fields.each do |fld|
        js[fld] = db[fld] if db[fld]
      end
      js
    end
=end
  end
end
