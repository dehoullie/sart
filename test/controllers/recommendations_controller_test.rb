require "test_helper"

class RecommendationsControllerTest < ActionDispatch::IntegrationTest
  test "should get mood" do
    get recommendations_mood_url
    assert_response :success
  end

  test "should get generate" do
    get recommendations_generate_url
    assert_response :success
  end
end
