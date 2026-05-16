class RemoveContentFieldsFromPosts < ActiveRecord::Migration[8.1]
  def change
    remove_column :posts, :title, :string
    remove_column :posts, :description, :string
    remove_column :posts, :content, :text
  end
end
