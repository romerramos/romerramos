class AddSpanishDraftRegeneratedAtToPostTranslations < ActiveRecord::Migration[8.1]
  def change
    add_column :post_translations, :spanish_draft_regenerated_at, :datetime
  end
end
