class ArDesign < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_designs do |t|
      t.string :description, default: ''
      t.string :body, default: ''
      t.string :css, default: ''
      t.string :rails_view, default: ''
      t.string :params, default: ''
      t.string :code, default: ''
      t.string :author
      t.integer :site_id

      t.integer :created_by
      t.integer :updated_by
      t.boolean :active, default: true
      t.timestamps
    end

  end
end
