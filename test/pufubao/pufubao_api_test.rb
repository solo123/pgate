require 'test_helper'

class PufubaoApiTest < ActionDispatch::IntegrationTest
  test 'pufubao pay' do
    return
    biz = Biz::PufubaoApi.new
    payment = payments(:one)
    #biz.pay(payment)
    #puts "-----pay to pufubao-----"
    #puts biz.req_string
  end
end
