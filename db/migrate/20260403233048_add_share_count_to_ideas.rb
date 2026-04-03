class AddShareCountToIdeas < ActiveRecord::Migration[8.1]
  def change
    add_column :ideas, :share_count, :integer, default: 0
  end
end
