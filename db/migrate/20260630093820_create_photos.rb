class CreatePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :photos do |t|
      t.string :title_en
      t.string :title_es
      t.text :caption_en
      t.text :caption_es
      t.integer :position
      t.boolean :published, null: false, default: true

      t.timestamps
    end
    add_index :photos, :position
  end
end
