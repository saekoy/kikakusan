ActiveRecord::Schema[8.1].define(version: 2026_04_02_071657) do
  create_table "ideas", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.integer "like_count", default: 0
    t.string "title"
    t.datetime "updated_at", null: false
  end
end
