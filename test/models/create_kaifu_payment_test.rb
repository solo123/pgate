require 'test_helper'

class CreateKaifuPaymentTest < ActionDispatch::IntegrationTest
  test "check mac when create kaifu_gateways" do
    p1 = client_payments(:t_p001)
    k = Biz::KaifuApi.create_kaifu_payment(p1)
    assert k
    assert !k.mac.empty?

  end
end
