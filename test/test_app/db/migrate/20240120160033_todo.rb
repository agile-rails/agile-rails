class Todo < ActiveRecord::Migration[7.0]
  def change
    create_table :todos do |t|
      t.integer :ar_user_id
      t.string :subject
      t.string :body
      t.datetime :time
      t.integer :priority, default: 1
      t.boolean :closed
      t.datetime :time_closed
      t.integer :created_by

      t.timestamps

      t.index :ar_user_id
    end

  end
end
