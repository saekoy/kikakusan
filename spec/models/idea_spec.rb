require 'rails_helper'

RSpec.describe Idea, type: :model do
  describe 'バリデーション' do
    it 'title と category があれば有効である' do
      idea = Idea.new(title: '残業あるある', category: 'トーク・雑談')
      expect(idea).to be_valid
    end

    it 'title が空では無効である' do
      idea = Idea.new(title: '', category: 'トーク・雑談')
      expect(idea).not_to be_valid
    end

    it 'category が空では無効である' do
      idea = Idea.new(title: '残業あるある', category: '')
      expect(idea).not_to be_valid
    end
  end

  describe 'デフォルト値' do
    it 'like_count のデフォルトは 0 である' do
      idea = Idea.new(title: '残業あるある', category: 'トーク・雑談')
      expect(idea.like_count).to eq(0)
    end

    it 'share_count のデフォルトは 0 である' do
      idea = Idea.new(title: '残業あるある', category: 'トーク・雑談')
      expect(idea.share_count).to eq(0)
    end
  end
end
