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

    saved = titles.map { |title| Idea.create!(title: title, category: params[:category]) }

    render json: { ideas: saved.map { |i| { id: i.id, title: i.title } } }
  end

  def like
    idea = Idea.find(params[:id])
    idea.increment!(:like_count)
    render json: { like_count: idea.like_count }
  end
end
