module Biz
  class KaifuApi < BizBase
    def send_kaifu_payment(client_payment)
      case client_payment.trans_type
      when 'P001'
        create_b001(client_payment)
      when 'P002'
        create_b002(client_payment)
      when 'P003'
        create_b001(client_payment)
      when 'P004'
        create_b002(client_payment)
      else
        {resp_code: '12', resp_desc: "无此交易：#{client_payment.trans_type}"}
      end
    end
    def create_b001(client_payment)
      js = {
        send_time: Time.now.strftime("%Y%m%d%H%M%S"),
        send_seq_id: "P1" + ('%06d' % client_payment.id),
        trans_type: 'B001',
        organization_id: CFG['org_id_b0'],
        pay_pass: client_payment.pay_pass,
        trans_amt: client_payment.amount.to_s,
        fee: client_payment.fee.to_s,
        card_no: client_payment.card_no,
        name: client_payment.card_holder_name,
        id_num: client_payment.person_id_num,
        body: "#{client_payment.client.name} - #{client_payment.order_title}",
        notify_url: CFG['pooul_notify_url'],
        callback_url: client_payment.callback_url
      }
      return create_kaifu_payment(client_payment, js)
    end
    def create_b002(client_payment)
      js = {
        send_time: Time.now.strftime("%Y%m%d%H%M%S"),
        send_seq_id: "P2" + ('%06d' % client_payment.id),
        trans_type: 'B002',
        organization_id: CFG['org_id_t1'],
        pay_pass: client_payment.pay_pass,
        trans_amt: client_payment.amount.to_s,
        fee: client_payment.fee.to_s,
        body: "#{client_payment.client.name} - #{client_payment.order_title}",
        notify_url: CFG['pooul_notify_url'],
        callback_url: client_payment.callback_url
      }
      return create_kaifu_payment(client_payment, js)
    end
    def create_kaifu_payment(client_payment, js)
      kf_js = kaifu_api_format(js)
      mac = js[:mac] = kf_js["mac"] = get_mac(kf_js, client_payment.trans_type)
      gw = KaifuGateway.new(js)
      gw.client_payment = client_payment
      gw.save

      ret_js = send_kaifu(kf_js, client_payment.trans_type)
      ret_js[:status] = (ret_js[:resp_code] == '00') ? 8 : 7
      client_payment.attributes = {
        resp_code: ret_js[:resp_code],
        resp_desc: ret_js[:resp_desc],
        img_url: ret_js[:img_url]
      }
      gw.update(ret_js)
      ret_js
    end

    def get_mac(js, trans_type)
      mab = get_mab(js)
      case trans_type
      when 'P001'
        Digest::MD5.hexdigest(mab + CFG['tmk_b0'])
      when 'P002'
        Digest::MD5.hexdigest(mab + CFG['tmk_b0'])
      when 'P003'
        kaifu_mac(mab, get_mackey)
      when 'P004'
        kaifu_mac(mab, get_mackey)
      else
        ''
      end
    end

    def get_mab(js)
      mab = ''
      js.keys.sort.each {|k| mab << js[k] if k != :mac && js[k] }
      mab
    end
    def get_mackey(refresh = false)
      if refresh || CFG['mac_key'].nil?
        biz = Biz::PosEncrypt.new
        mac_key = KaifuSignin.last.terminal_info
        key = biz.e_mak_decrypt([mac_key].pack('H*'), CFG['tmk_b0'])
        CFG['mac_key'] = key.unpack('H*')[0].upcase
      end
      CFG['mac_key']
    end

    def send_kaifu(js, trans_type)
      if trans_type == 'P001' || trans_type == 'P002'
        uri = URI(CFG['openid_api_url'])
      else
        uri = URI(CFG['app_api_url'])
      end
      resp = Net::HTTP.post_form(uri, data: js.to_json)
      if resp.is_a?(Net::HTTPRedirection)
        j = {resp_code: '00', resp_desc: '交易成功', redirect_url: resp['location']}
      elsif resp.is_a?(Net::HTTPOK)
        begin
          body_txt = resp.body.force_encoding('UTF-8')
          j = js_to_app_format(JSON.parse(body_txt)).symbolize_keys
          j[:resp_desc] = '[server] ' + j[:resp_desc]
        rescue => e
          j = {resp_code: '99', resp_desc: "ERROR: #{e.message}\n#{body_txt}"}
        end
      else
        j = {resp_code: '96', resp_desc: '系统故障:' + resp.to_s + "\n" + resp.to_hash.to_s}
      end
      j
    end

    def kaifu_api_format(js)
      Hash[js.map {|k,v| [k.to_s.camelize(:lower).to_sym, v]}]
    end
    def js_to_app_format(js)
      Hash[js.map {|k,v| [k.to_s.underscore, v]}]
    end

    def kaifu_mac(mab, key)
      mab = mab.encode('GBK')
      biz = Biz::PosEncrypt.new
      r = biz.pos_mac(mab, key)
      r.unpack('H*')[0][0..7].upcase
    end

  end
end
