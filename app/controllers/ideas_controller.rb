class IdeasController < ApplicationController
  def index
  end

  def create
    dummy_ideas = Array.new(10) { |i| "企画アイデア#{i + 1}" }
    render json: { ideas: dummy_ideas }
  end
end
