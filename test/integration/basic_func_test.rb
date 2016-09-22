require 'test_helper'

class BasicFuncTest < ActionDispatch::IntegrationTest
  test "mab" do
    js = {a: '123', c: 'abc', b: '999'}
    biz = Biz::KaifuApi.new
    assert_equal '123999abc', biz.get_mab(js)
  end
  test "mab with mac" do
    js = {a: '123', c: 'abc', b: '999', mac: 'mac'}
    biz = Biz::KaifuApi.new
    assert_equal '123999abc', biz.get_mab(js)
  end
end
