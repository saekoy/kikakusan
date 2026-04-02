require 'rails_helper'

RSpec.describe 'Ideas', type: :system do
  before do
    driven_by(:rack_test)
  end

  describe 'トップページアクセスの検証' do
    it 'Idea#top という文字列が表示される' do
      visit '/'

      expect(page).to have_content('Ideas#index')
    end
  end
end