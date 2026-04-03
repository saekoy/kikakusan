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
      expect(page).to have_content('トーク・雑談')
      expect(page).to have_content('ゲーム・チャレンジ')
      expect(page).to have_content('歌・パフォーマンス')
      expect(page).to have_content('リスナー参加型')
    end

    it '今日の一言の入力欄が表示される' do
      expect(page).to have_css('textarea')
    end

    it '企画を考えてもらう ボタンが表示される' do
      expect(page).to have_button('企画を考えてもらう')
    end
  end
end
