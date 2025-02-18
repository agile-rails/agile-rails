class ArSetup < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_setups do |t|
      t.string  :name
      t.text    :data
      t.text    :form
      t.string  :edit_ids

      t.integer :created_by
      t.integer :updated_by
      t.timestamps

      t.index :name
    end
  end
end
