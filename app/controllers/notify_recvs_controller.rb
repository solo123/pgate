class NotifyRecvsController < ApplicationController
  def notify
    save_to_db(request, action_name, params[:sender])
    render plain: get_notify_return(params[:sender])
  end
  def callback
    save_to_db(request, action_name, params[:sender])
    render plain: '这里是：CallBack 页面！'
  end
  def save_to_db(request, method, sender)
    rv = NotifyRecv.new
    rv.method = method
    rv.ref = request.params['ref']
    rv.sender = sender
    rv.send_host = request.remote_ip #headers['remote-addr']
    rv.params = request.params.to_s
    rv.data = params['data']
    rv.status = 0
    rv.save!

    h = HttpLog.new
    h.method = method
    h.sender = rv
    h.remote_detail = request.inspect
    h.send_data = params.inspect
    h.save!

    Biz::NotifyBiz.send_notify(rv)
  end
  def get_notify_return(sender)
    AppConfig.get(sender, 'notify.return') || 'SUCCESS'
  end

end
