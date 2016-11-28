class SendNotifyJob < ApplicationJob
  include SuckerPunch::Job
  queue_as :default

  #params: n = client_payment.id
  def perform(*args)
    n = args[0]
    return false unless n > 0

    pm = Payment.find(n)
    pr = pm.pay_result
    pr.notify_times = 0 unless pr.notify_times
    return false unless pm && pr && pr.notify_times < 100

    Biz::PaymentBiz.send_notify(pm)
    if pr.notify_times < 8
      wait_times = [10, 60, 120, 300, 1200, 3600, 7200, 36000]
      SendNotifyJob.perform_in(wait_times[pr.notify_times], n)
    end
    true
  end
end
