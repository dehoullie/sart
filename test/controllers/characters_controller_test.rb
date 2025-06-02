require "test_helper"

class CharactersControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get characters_create_url
    assert_response :success
  end

  test "should get destroy" do
    get characters_destroy_url
    assert_response :success
  end
end
