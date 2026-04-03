class IdeasController < ApplicationController
  def index
  end

  def create
    ideas = GeminiService.new(
      category: params[:category],
      memo:     params[:memo],
      profile:  params[:profile] || {}
    ).call

    render json: { ideas: ideas }
  end
end
