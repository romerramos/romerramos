class CreatePostGenerations < ActiveRecord::Migration[8.1]
  def change
    create_table :post_generations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: true, foreign_key: { on_delete: :nullify }
      t.string :source_locale, null: false
      t.string :status, null: false, default: "queued"
      t.string :failure_reason
      t.text :transcript
      t.string :transcription_model
      t.string :generation_model
      t.timestamps
    end

    add_index :post_generations, :status
  end
end
