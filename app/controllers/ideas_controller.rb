class IdeasController < ApplicationController
  def index
  end

  def create
    unless recaptcha_valid?(params[:recaptcha_token])
      render json: { error: 'bot_detected' }, status: :forbidden
      return
    end

    memo = params[:memo].to_s.slice(0, 100)

    titles = GeminiService.new(
      category: params[:category],
      memo: memo,
      profile: params[:profile] || {},
      liked_ideas: params[:liked_ideas] || []
    ).call

    render json: { ideas: titles }
  end

  def like
    idea = Idea.find_or_create_by!(title: params[:title], category: params[:category])
    idea.update!(like_count: idea.like_count + 1)
    render json: { like_count: idea.like_count }
  end

  def share
    idea = Idea.find_or_create_by!(title: params[:title], category: params[:category])
    idea.update!(share_count: idea.share_count + 1)
    render json: { share_count: idea.share_count }
  end

  private

  def recaptcha_valid?(token)
    return true if Rails.env.test?
    return true if ENV['RECAPTCHA_SECRET_KEY'].blank?

    uri = URI('https://www.google.com/recaptcha/api/siteverify')
    response = Net::HTTP.post_form(uri, {
                                     secret: ENV.fetch('RECAPTCHA_SECRET_KEY', nil),
                                     response: token.to_s
                                   })
    body = JSON.parse(response.body)
    body['success'] && body['score'].to_f >= 0.5
  rescue StandardError
    true
  end
end
