module Biz
  class PaymentBiz < BizBase
    attr_reader :err_code, :err_desc
    FLDS_PAYMENT = %w(
      app_id open_id order_num order_time order_title
      attach_info amount fee remote_ip terminal_num
      method callback_url notify_url
    ).freeze

    #params: prv = req_recv
    def pay(prv)
      @err_code = '00'
      @err_desc = ''
      js_recv = parse_data_json(prv.data)
      return unless js_recv && @org

      payment = prv.build_payment
      payment.org = @org
      Biz::PublicTools.update_fields_json(FLDS_PAYMENT, payment, js_recv)
      payment.save!

      biz = Biz::ChannelBiz.new
      biz.send_channel(payment)
      @err_code = biz.err_code
      @err_desc = biz.err_desc
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

      required_fields = [:org_code, :method, :sign]
      if !(miss_flds = required_fields.select{|f| js[f].nil? }).empty?
        @err_code = '30'
        @err_desc = '报文错，缺少字段：' + miss_flds.join(', ')
        return nil
      end

      @org = Org.valid_status.find_by(org_code: js[:org_code])
      if @org.nil?
        @err_code = '03'
        @err_desc = "无此商户: #{js[:org_code]}"
        return nil
      end

      if js[:sign].upcase != Biz::PublicTools.get_mac(js, @org.tmk)
        @err_code = 'A0'
        @err_desc = '检验mac错'
        return nil
      end
      js
    end


=begin


    #params c = client_payment
    def self.send_notify(c)
      notify_time = Time.now
      js = {
        org_id: c.org_id,
        trans_type: c.trans_type,
        order_time: c.order_time,
        order_id: c.order_id,
        amount: c.amount,
        attach_info: c.attach_info,
        resp_code: c.resp_code,
        resp_desc: c.resp_desc,
        pay_code: c.pay_code,
        pay_desc: c.pay_desc,
        notify_time: notify_time.strftime("%Y%m%d%H%M%S"),
        op_time: c.updated_at.strftime("%Y%m%d%H%M%S")
      }
      mab = Biz::PubEncrypt.get_mab(js)
      js[:mac] = Biz::PubEncrypt.md5(mab + c.client.tmk)
      txt = Biz::WebBiz.post_data(c.notify_url, js.to_json, c)
      c.notify_times += 1
      c.last_notify = notify_time
      c.notify_status = 8 if txt =~ /(true)|(ok)|(success)/
      c.save!
    end

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
