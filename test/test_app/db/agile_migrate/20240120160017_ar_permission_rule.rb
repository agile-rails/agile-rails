class ArPermissionRule < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_permission_rules do |t|
      t.integer :ar_permission_id
      t.integer :ar_role_id
      t.integer :permission, default: 0
      t.boolean :active, default: true

      t.integer :created_by
      t.integer :updated_by
      t.timestamps

      t.index :ar_permission_id
    end

  end
end
