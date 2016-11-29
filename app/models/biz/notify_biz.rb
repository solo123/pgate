module Biz
  class NotifyBiz < BizBase
    #params: rv = PostRecv
    def self.send_notify(rv)
      return nil if rv.status > 0
      if rv.sender == 'pfb'
       payment_id = Biz::PufubaoApi.process_notify(rv)
       SendNotifyJob.new.perform(payment_id)
      end
    end

  end
end
