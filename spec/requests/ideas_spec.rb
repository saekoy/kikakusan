require 'rails_helper'

RSpec.describe 'Ideas', type: :request do
  describe 'GET /' do
    it 'HTTP ステータス 200 を返す' do
      get '/'
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /ideas' do
    context '正常なパラメータを送信した場合' do
      let(:valid_params) do
        { category: 'トーク・雑談', memo: '今日は残業でクタクタ' }
      end
      let(:fake_titles) { Array.new(10) { |i| "企画タイトル#{i + 1}" } }

      before do
        allow_any_instance_of(GeminiService).to receive(:call).and_return(fake_titles)
      end

      it 'HTTP ステータス 200 を返す' do
        post '/ideas', params: valid_params
        expect(response).to have_http_status(200)
      end

      it 'JSON形式で返す' do
        post '/ideas', params: valid_params
        expect(response.content_type).to include('application/json')
      end

      it 'ideas キーを含む' do
        post '/ideas', params: valid_params
        json = JSON.parse(response.body)
        expect(json).to have_key('ideas')
      end

      it 'ideas が10件返る' do
        post '/ideas', params: valid_params
        json = JSON.parse(response.body)
        expect(json['ideas'].length).to eq(10)
      end

      it 'DB には保存されない' do
        expect {
          post '/ideas', params: valid_params
        }.not_to change(Idea, :count)
      end
    end
  end

  describe 'POST /ideas/like' do
    let(:like_params) { { title: '残業あるある', category: 'トーク・雑談' } }

    it 'HTTP ステータス 200 を返す' do
      post '/ideas/like', params: like_params
      expect(response).to have_http_status(200)
    end

    it 'いいねされた企画が DB に保存される' do
      expect {
        post '/ideas/like', params: like_params
      }.to change(Idea, :count).by(1)
    end

    it '同じ企画に2回いいねしても DB レコードは1件' do
      expect {
        2.times { post '/ideas/like', params: like_params }
      }.to change(Idea, :count).by(1)
    end

    it 'like_count が増える' do
      post '/ideas/like', params: like_params
      expect(Idea.find_by(title: '残業あるある').like_count).to eq(1)
    end
  end
end
