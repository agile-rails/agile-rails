class ArPolicyRule < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_policy_rules do |t|
      t.integer :ar_role_id
      t.integer :permission, default: 0

      t.boolean :active, default: true
      t.integer :ar_policy_id

      t.timestamps
      t.integer :created_by
      t.integer :updated_by

      t.index :ar_policy_id
    end

  end
end
