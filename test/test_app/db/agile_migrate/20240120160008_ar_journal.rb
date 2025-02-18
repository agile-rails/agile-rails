class ArJournal < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_journals do |t|
      t.integer :user_id
      t.integer :site_id
      t.integer :record_id
      t.string :operation
      t.string :tables
      t.string :ids
      t.string :ip
      t.datetime :time
      t.string :diff

      t.index :user_id
      t.index [:tables, :record_id]
    end

  end
end
