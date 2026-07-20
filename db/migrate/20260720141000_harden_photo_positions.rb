class HardenPhotoPositions < ActiveRecord::Migration[8.1]
  def change
    change_column_null :photos, :position, false
    remove_index :photos, :position
    add_index :photos, :position, unique: true
  end
end
