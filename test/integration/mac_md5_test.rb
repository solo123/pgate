require 'test_helper'

class MacMd5Test < ActionDispatch::IntegrationTest
  test "mab" do
    js = {a: '123', c: 'abc', b: '999'}
    assert_equal 'a=123&b=999&c=abc', Biz::PublicTools.get_mab(js)
  end
  test "mab with mac" do
    js = {a: '123', c: 'abc', b: '999', mac: 'mac'}
    assert_equal 'a=123&b=999&c=abc', Biz::PublicTools.get_mab(js)
  end
end
