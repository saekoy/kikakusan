class IdeasController < ApplicationController
  def index
  end

  def create
    titles = GeminiService.new(
      category:    params[:category],
      memo:        params[:memo],
      profile:     params[:profile] || {},
      liked_ideas: params[:liked_ideas] || []
    ).call

    render json: { ideas: titles }
  end

  def like
    idea = Idea.find_or_create_by!(title: params[:title], category: params[:category])
    idea.increment!(:like_count)
    render json: { like_count: idea.like_count }
  end
end
