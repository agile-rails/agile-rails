class ArPart < ActiveRecord::Migration[7.0]

  def change
    create_table :ar_parts do |t|
      t.string  :name, default: ''
      t.string  :link
      t.string  :description, default: ''
      t.string  :picture
      t.string  :thumbnail
      t.string  :body, default: ''
      t.string  :css, default: ''
      t.string  :script, default: ''
      t.string  :script_type, default: ''
      t.string  :params, default: ''
      t.string  :div_id
      t.integer :site_id
      t.integer :order, default: 0
      t.boolean :active, default: true
      t.datetime :valid_from
      t.datetime :valid_to
      t.integer :policy_id

      t.integer :parent_id
      t.string  :parent_type
      t.integer :created_by
      t.integer :updated_by
      t.timestamps

      t.index [:parent_type, :parent_id], name: 'ar_part_by_parent'
    end
  end

end