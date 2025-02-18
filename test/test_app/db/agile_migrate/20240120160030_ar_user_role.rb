class ArUserRole < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_user_roles do |t|
      t.integer :ar_role_id
      t.integer :ar_user_id
      t.date    :valid_from
      t.date    :valid_to
      t.boolean :active, default: true

      t.integer :created_by
      t.integer :updated_by
      t.timestamps

      t.index [:ar_user_id, :ar_role_id], name: 'index_ar_user_roles_1'
      t.index [:ar_role_id, :ar_user_id], name: 'index_ar_user_roles_2'
    end
  end
end
