class Idea < ApplicationRecord
  validates :title, presence: true
  validates :category, presence: true
end
