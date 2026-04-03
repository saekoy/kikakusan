require 'rails_helper'

RSpec.describe 'Ideas', type: :system do
  before do
    driven_by(:rack_test)
  end

  describe 'トップページアクセスの検証' do
    before { visit '/' }

    it 'きかくさん という文字列が表示される' do
      expect(page).to have_content('きかくさん')
    end

    it 'ジャンル選択肢が4つ表示される' do
      expect(page).to have_content('ざつだん')
      expect(page).to have_content('ゲーム')
      expect(page).to have_content('うた')
      expect(page).to have_content('おまかせ')
    end

    it '今日のことの入力欄が表示される' do
      expect(page).to have_css('textarea')
    end

    it '企画を考える ボタンが表示される' do
      expect(page).to have_button('企画を考える')
    end
  end
end
