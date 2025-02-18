class ArFolderRule < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_folder_rules do |t|
      t.references :ar_folder_permission
      t.belongs_to :ar_role
      t.integer    :permission, default: 0
      t.boolean    :active, default: true

      t.integer :created_by
      t.integer :updated_by
      t.timestamps
    end
  end
end
