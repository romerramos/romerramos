class AddPublicationToPostTranslations < ActiveRecord::Migration[8.1]
  def change
    add_column :post_translations, :published, :boolean
    add_column :post_translations, :published_at, :datetime
    change_column_null :post_translations, :title, true
  end
end
