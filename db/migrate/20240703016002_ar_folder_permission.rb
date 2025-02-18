class ArFolderPermission < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_folder_permissions do |t|
      t.string  :folder_name
      t.boolean :inherited, default: true
      t.boolean :active,    default: true

      t.integer :created_by
      t.integer :updated_by
      t.timestamps

      t.index :folder_name, unique: true
    end
  end
end
