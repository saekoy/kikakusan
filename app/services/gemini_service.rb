require 'net/http'

class GeminiService
  API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent'

  def initialize(category:, memo:, profile: {}, liked_ideas: [])
    @category    = category
    @memo        = memo
    @profile     = profile
    @liked_ideas = Array(liked_ideas)
  end

  def call
    response = request_to_gemini(build_prompt)
    parse_ideas(response)
  end

  private

  def build_prompt
    profile_text = build_profile_text
    memo_text    = @memo.present? ? "今日のこと：#{@memo}" : ''
    liked_text   = @liked_ideas.present? ? "過去にいいねした企画：#{@liked_ideas.join('、')}" : ''

    <<~PROMPT
      あなたはVライバーの企画ディレクターです。
      平日は仕事や学業で忙しく毎日配信するライバー向けに、疲れていても回せる企画を10個考えてください。

      制約：準備10分以内・テンションが低くても成立・コメントが少なくても成立

      配信者情報：#{profile_text}
      ジャンル：#{@category}#{" / #{memo_text}" unless memo_text.empty?}
      #{liked_text unless liked_text.empty?}

      出力：企画タイトルのみのJSON配列。説明不要。各20文字以内。
      例：["タイトル1","タイトル2"]
    PROMPT
  end

  def build_profile_text
    parts = []
    parts << "性別：#{@profile[:gender]}"          if @profile[:gender].present?
    parts << "年齢：#{@profile[:age]}"              if @profile[:age].present?
    parts << "家族構成：#{@profile[:family]}"       if @profile[:family].present?
    parts << "配信キャラ：#{@profile[:character]}"  if @profile[:character].present?
    parts << "リスナー層：#{@profile[:listener]}"   if @profile[:listener].present?
    parts << "自由記入：#{@profile[:memo]}"         if @profile[:memo].present?
    parts.empty? ? '情報なし' : parts.join('、')
  end

  def request_to_gemini(prompt)
    uri  = URI(API_URL)
    body = {
      contents: [{
        parts: [{ text: prompt }]
      }]
    }.to_json

    http         = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request      = Net::HTTP::Post.new(uri)
    request['Content-Type']   = 'application/json'
    request['x-goog-api-key'] = ENV.fetch('GEMINI_API_KEY', nil)
    request.body = body

    http.request(request)
  end

  def parse_ideas(response)
    body      = JSON.parse(response.body)
    text      = body.dig('candidates', 0, 'content', 'parts', 0, 'text')
    json_text = text&.match(/\[.*\]/m)&.to_s
    JSON.parse(json_text || '[]')
  rescue StandardError => e
    Rails.logger.error "GeminiService error: #{e.message}"
    []
  end
end
