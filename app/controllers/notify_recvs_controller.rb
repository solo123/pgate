class NotifyRecvsController < ApplicationController
  def notify
    do_notify
  end
  def callback
    do_notify
  end
  def do_notify
    save_to_db(request, action_name, params[:sender])
    render plain: '--OK--'
  end
  def save_to_db(request, method, sender)
    rv = NotifyRecv.new
    rv.method = method
    rv.sender = sender
    rv.send_host = request.headers['remote-addr']
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
  end


end
