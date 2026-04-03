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

      it 'ideas の各要素が id と title を持つ' do
        post '/ideas', params: valid_params
        json = JSON.parse(response.body)
        idea = json['ideas'].first
        expect(idea).to have_key('id')
        expect(idea).to have_key('title')
      end

      it '企画が DB に保存される' do
        expect {
          post '/ideas', params: valid_params
        }.to change(Idea, :count).by(10)
      end
    end
  end

  describe 'POST /ideas/:id/like' do
    let!(:idea) { Idea.create!(title: '残業あるある', category: 'トーク・雑談') }

    it 'HTTP ステータス 200 を返す' do
      post "/ideas/#{idea.id}/like"
      expect(response).to have_http_status(200)
    end

    it 'like_count が1増える' do
      expect {
        post "/ideas/#{idea.id}/like"
      }.to change { idea.reload.like_count }.by(1)
    end
  end
end
