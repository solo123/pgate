module Biz
  class PaymentBiz
    def check_required_params(params)
      if params.nil? || params.is_a?(String)
        return {resp_code: '30', resp_desc: '报文为空'}
      end
      js = {resp_code: '00'}
      miss_flds =  []
      %W(org_id trans_type mac).each do |fld|
        if params[fld].nil?
          miss_flds << fld.to_s
        end
      end
      if miss_flds.length > 0
        js = {resp_code: '30', resp_desc: '报文错，缺少字段：' + miss_flds.join(', ')}
      else
        client = Client.find_by(org_id: params['org_id'])
        if client.nil?
          js = {resp_code: '03', resp_desc: "无此商户: #{params['org_id']}"}
        else
          mab = ''
          params.keys.sort.each do |fld|
            if fld != "mac"
              mab << params[fld]
            end
          end
          mac = Digest::MD5.hexdigest(mab + client.tmk).upcase
          if mac.upcase != params['mac'].upcase
            js = {resp_code: 'A0', resp_desc: '检验mac错'}
          end
        end
      end
      js
    end
  end
end
