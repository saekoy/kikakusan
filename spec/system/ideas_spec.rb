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

    it 'きぶんの入力欄が表示される' do
      expect(page).to have_css('textarea[data-ideas-target="todayMemo"]')
    end

    it 'きぶんの入力欄に100文字の制限がある' do
      expect(page).to have_css('textarea[data-ideas-target="todayMemo"][maxlength="100"]')
    end

    it '企画を考える ボタンが表示される' do
      expect(page).to have_button('企画を考える')
    end
  end

  describe 'プロフィール編集画面の検証' do
    before { visit '/' }

    it '自由記入欄に200文字の制限がある' do
      expect(page).to have_css('textarea[data-ideas-target="editMemo"][maxlength="200"]')
    end

    it 'プロフィール編集画面のジャンル選択肢が正しい' do
      expect(page).to have_content('10代')
      expect(page).to have_content('20代')
      expect(page).to have_content('30代')
      expect(page).to have_content('40代')
      expect(page).to have_content('50代以上')
    end
  end
end
