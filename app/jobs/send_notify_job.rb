class SendNotifyJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  #params: n = client_payment.id
  def perform(*args)
    n = args[0]
    return false unless n > 0

    c = ClientPayment.find(n)
    return false unless c && c.notify_status != 8

    Biz::PaymentBiz.send_notify(c)
    if c.notify_status != 8 && c.notify_times < 6
      wait_times = [60, 120, 300, 1200, 3600, 7200, 36000]
      SendNotifyJob.perform_in(wait_times[c.notify_times], n)
    end
    true
  end
end
