class AddPublishedToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :published, :boolean, default: true, null: false
    change_column_default :posts, :published, from: true, to: false
  end
end
