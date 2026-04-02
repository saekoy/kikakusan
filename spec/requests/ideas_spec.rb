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

      it 'HTTP ステータス 200 を返す' do
        post '/ideas', params: valid_params
        expect(response).to have_http_status(200)
      end

      it 'JSON形式で返す' do
        post '/ideas', params: valid_params
        expect(response.content_type).to include('application/json')
      end

      it 'ideasキーを含む' do
        post '/ideas', params: valid_params
        json = JSON.parse(response.body)
        expect(json).to have_key('ideas')
      end

      it 'ideas が10件返る' do
        post '/ideas', params: valid_params
        json = JSON.parse(response.body)
        expect(json['ideas'].length).to eq(10)
      end
    end
  end
end
