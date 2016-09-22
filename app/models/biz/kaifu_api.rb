module Biz
  class KaifuApi
    ORG_ID = 'puerhanda'
    TMK = '9DB9095654D1FA7763F32E6B4E922140'
    API_URL_OPENID = 'http://61.135.202.242/payform/organization_ymf'
    API_URL_QUERY = 'http://61.135.202.242:8022/payform/organization'
    API_URL_APP = 'http://61.135.202.242:8020/payform/organization'
    NOTIFY_URL = 'http://112.74.184.236:8010/recv_notify'
    CALLBACK_URL = 'http://112.74.184.236:8010/recv_callback'
    #OPENID_B001_FLDS = "sendTime,sendSeqId,transType,organizationId,payPass,transAmt,fee,cardNo,name,idNum,body,notifyUrl,callbackUrl"

    def send_kaifu_payment(client_payment)
      case client_payment.trans_type
      when 'P001'
        create_b001(client_payment)
      when 'P002'
        create_b002(client_payment)
      when 'P003'
        create_b001(client_payment)
      else
        {resp_code: '12', resp_desc: "无此交易：#{client_payment.trans_type}"}
      end
    end
    def create_b001(client_payment)
      js = {
        send_time: Time.now.strftime("%Y%m%d%H%M%S"),
        send_seq_id: "P1" + ('%06d' % client_payment.id),
        trans_type: 'B001',
        organization_id: ORG_ID,
        pay_pass: client_payment.pay_pass,
        trans_amt: client_payment.amount.to_s,
        fee: client_payment.fee.to_s,
        card_no: client_payment.card_no,
        name: client_payment.card_holder_name,
        id_num: client_payment.person_id_num,
        body: "#{client_payment.client.name} - #{client_payment.order_title}",
        notify_url: NOTIFY_URL,
        callback_url: client_payment.callback_url
      }
      return create_kaifu_payment(client_payment, js)
    end
    def create_b002(client_payment)
      js = {
        send_time: Time.now.strftime("%Y%m%d%H%M%S"),
        send_seq_id: "P2" + ('%06d' % client_payment.id),
        trans_type: 'B002',
        organization_id: ORG_ID,
        pay_pass: client_payment.pay_pass,
        trans_amt: client_payment.amount.to_s,
        fee: client_payment.fee.to_s,
        body: "#{client_payment.client.name} - #{client_payment.order_title}",
        notify_url: NOTIFY_URL,
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
        Digest::MD5.hexdigest(mab + TMK)
      when 'P002'
        Digest::MD5.hexdigest(mab + TMK)
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
      js.keys.sort.each {|k| mab << js[k] if k.to_s != 'mac' && js[k] }
      mab
    end
    def get_mackey
      biz = Biz::PosEncrypt.new
      mac_key = KaifuSignin.last.terminal_info
      key = biz.e_mak_decrypt([mac_key].pack('H*'), TMK)
      puts "terminal_info=" + mac_key
      key.unpack('H*')[0].upcase
    end

    def send_kaifu(js, trans_type)
      if trans_type == 'P001' || trans_type == 'P002'
        uri = URI(API_URL_OPENID)
      else
        uri = URI(API_URL_APP)
      end
      resp = Net::HTTP.post_form(uri, data: js.to_json)
=begin
      Rails.logger.level = 0
      Rails.logger.info '------KaiFu------'
      Rails.logger.info 'data = ' + js.to_json.to_s
      Rails.logger.info 'resp = ' + resp.to_s
      Rails.logger.info 'resp = ' + resp.to_hash.to_s
      Rails.logger.info 'resp.body = ' + resp.body.to_s
      Rails.logger.info 'resp.body.class = ' + resp.body.class.to_s
=end
      if resp.is_a?(Net::HTTPRedirection)
        j = {resp_code: '00', resp_desc: '交易成功', redirect_url: resp['location']}
      elsif resp.is_a?(Net::HTTPOK)
        begin
          body_txt = resp.body.force_encoding('UTF-8')
          j = js_to_app_format JSON.parse(body_txt)
          j.symbolize_keys!
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
      r = {}
      js.keys.each {|k| r[k.to_s.camelize(:lower)] = js[k].to_s}
      r
    end
    def js_to_app_format(js)
      r = {}
      js.keys.each {|k| r[k.to_s.underscore] = js[k].to_s}
      r
    end

    def kaifu_mac(mab, key)
      mab = mab.encode('GBK')
      biz = Biz::PosEncrypt.new
      r = biz.pos_mac(mab, key)
      r.unpack('H*')[0][0..7].upcase
    end

  end
end
