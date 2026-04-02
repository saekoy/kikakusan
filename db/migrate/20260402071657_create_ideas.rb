class CreateIdeas < ActiveRecord::Migration[8.1]
  def change
    create_table :ideas do |t|
      t.string :title
      t.string :category
      t.integer :like_count

      t.timestamps
    end
  end
end
