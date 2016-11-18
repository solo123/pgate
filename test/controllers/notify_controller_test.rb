require 'test_helper'

class NotifyControllerTest < ActionDispatch::IntegrationTest
  test "get a notify" do
    assert_recognizes({controller: 'notify_recvs', action: 'notify', ref: 'order_num', sender: 'test_sender', abc: 'val_abc'}, {path: '/notify/order_num/test_sender', method: :post}, { abc: "val_abc" })
  end
end
