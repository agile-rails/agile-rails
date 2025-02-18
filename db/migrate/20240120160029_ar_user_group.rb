class ArUserGroup < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_user_groups do |t|
      t.integer :ar_user_id
      t.integer :group_id

      t.index :ar_user_id
      t.index :group_id
    end

  end
end
