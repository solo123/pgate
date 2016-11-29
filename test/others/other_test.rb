require 'test_helper'

class SendNotifyTest < ActionDispatch::IntegrationTest
  test "webmock stub" do
    return
    stub_request(:post, "myweb").to_return(
      body: "abc", status: 200,
      headers: { 'Content-Length' => 3 }
    )

    js = {a: 1, b: 'abc'}
    uri = URI('http://myweb')
    resp = Net::HTTP.post_form(uri, js)
    byebug
  end
end
