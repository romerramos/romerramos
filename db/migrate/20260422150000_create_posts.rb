class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.datetime :published_at
      t.timestamps
    end
  end
end
