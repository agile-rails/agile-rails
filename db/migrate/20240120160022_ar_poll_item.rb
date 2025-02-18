class ArPollItem < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_poll_items do |t|
      t.string  :name, default: ''
      t.string  :text, default: ''
      t.string  :field_type, default: ''
      t.string  :size, default: '10'
      t.boolean :mandatory, default: false
      t.string  :separator, default: ''
      t.string  :options, default: ''
      t.integer :order, default: 0

      t.integer :ar_poll_id
      t.boolean :active, default: true

      t.integer :created_by
      t.integer :updated_by
      t.timestamps

      t.index :ar_poll_id
    end
  end
end
