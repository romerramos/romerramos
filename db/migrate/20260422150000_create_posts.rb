class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :description
      t.text :content
      t.datetime :published_at
      t.timestamps
    end
  end
end
