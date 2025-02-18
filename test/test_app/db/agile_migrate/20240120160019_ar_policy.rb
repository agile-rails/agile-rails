class ArPolicy < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_policies do |t|
      t.string  :name
      t.string  :description, default: ''
      t.boolean :is_default, default: false
      t.boolean :active, default: true
      t.string  :message, default: ''
      t.string  :rules, default: ''

      t.integer :ar_site_id

      t.integer :created_by
      t.integer :updated_by
      t.timestamps

      t.index :ar_site_id
    end

  end
end
