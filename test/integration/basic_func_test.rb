require 'test_helper'

class BasicFuncTest < ActionDispatch::IntegrationTest
  test "mab" do
    js = {a: '123', c: 'abc', b: '999'}
    assert_equal '123999abc', Biz::PubEncrypt.get_mab(js)
  end
  test "mab with mac" do
    js = {a: '123', c: 'abc', b: '999', mac: 'mac'}
    assert_equal '123999abc', Biz::PubEncrypt.get_mab(js)
  end
end
