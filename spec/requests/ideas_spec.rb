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
        { category: '雑談', memo: '今日はテンション高め' }
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
        json = response.parsed_body
        expect(json).to have_key('ideas')
      end

      it 'ideas が10件返る' do
        post '/ideas', params: valid_params
        json = response.parsed_body
        expect(json['ideas'].length).to eq(10)
      end

      it 'DB には保存されない' do
        expect do
          post '/ideas', params: valid_params
        end.not_to change(Idea, :count)
      end
    end

    context 'GeminiService が空配列を返した場合' do
      before do
        allow_any_instance_of(GeminiService).to receive(:call).and_return([])
      end

      it 'ideas が空配列で返る' do
        post '/ideas', params: { category: '雑談', memo: '' }
        json = response.parsed_body
        expect(json['ideas']).to eq([])
      end
    end

    context 'reCAPTCHA 検証に失敗した場合' do
      before do
        allow_any_instance_of(IdeasController).to receive(:recaptcha_valid?).and_return(false)
      end

      it 'HTTP ステータス 403 を返す' do
        post '/ideas', params: { category: '雑談', memo: '' }
        expect(response).to have_http_status(403)
      end
    end

    context 'メモが100文字を超えた場合' do
      let(:long_memo) { 'あ' * 101 }
      let(:fake_titles) { Array.new(10) { |i| "企画タイトル#{i + 1}" } }

      it '100文字に切り捨てられてGeminiに渡される' do
        truncated = long_memo.slice(0, 100)
        expect_any_instance_of(GeminiService).to receive(:initialize).with(
          hash_including(memo: truncated)
        ).and_call_original
        allow_any_instance_of(GeminiService).to receive(:call).and_return(fake_titles)
        post '/ideas', params: { category: '雑談', memo: long_memo }
      end
    end
  end

  describe 'POST /ideas/like' do
    let(:like_params) { { title: '残業あるある', category: '雑談' } }

    it 'HTTP ステータス 200 を返す' do
      post '/ideas/like', params: like_params
      expect(response).to have_http_status(200)
    end

    it 'いいねされた企画が DB に保存される' do
      expect do
        post '/ideas/like', params: like_params
      end.to change(Idea, :count).by(1)
    end

    it '同じ企画に2回いいねしても DB レコードは1件' do
      expect do
        2.times { post '/ideas/like', params: like_params }
      end.to change(Idea, :count).by(1)
    end

    it 'like_count が増える' do
      post '/ideas/like', params: like_params
      expect(Idea.find_by(title: '残業あるある').like_count).to eq(1)
    end
  end

  describe 'POST /ideas/share' do
    let(:share_params) { { title: '残業あるある', category: '雑談' } }

    it 'HTTP ステータス 200 を返す' do
      post '/ideas/share', params: share_params
      expect(response).to have_http_status(200)
    end

    it 'シェアされた企画が DB に保存される' do
      expect do
        post '/ideas/share', params: share_params
      end.to change(Idea, :count).by(1)
    end

    it '同じ企画を2回シェアしても DB レコードは1件' do
      expect do
        2.times { post '/ideas/share', params: share_params }
      end.to change(Idea, :count).by(1)
    end

    it 'share_count が増える' do
      post '/ideas/share', params: share_params
      expect(Idea.find_by(title: '残業あるある').share_count).to eq(1)
    end
  end
end
