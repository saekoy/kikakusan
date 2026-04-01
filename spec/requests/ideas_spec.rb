require 'rails_helper'

RSpec.describe "Ideas", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/ideas/index"
      expect(response).to have_http_status(:success)
    end
  end

end
