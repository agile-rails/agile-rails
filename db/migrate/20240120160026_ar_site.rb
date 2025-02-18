class ArSite < ActiveRecord::Migration[7.0]
  def change
    create_table :ar_sites do |t|
      t.string :name
      t.string :description
      t.string :homepage_link
      t.string :error_link
      t.string :header
      t.string :css
      t.string :route_name
      t.string :page_title
      t.string :page_class, default: 'ArPage'
      t.string :site_layout, default: 'content'
      t.string :menu_class, default: 'ArMenu'
      t.string :request_processor
      t.string :files_directory
      t.string :logo
      t.string :favicon
      t.string :menu_name
      t.integer :menu_id
      t.string :settings
      t.string :alias_for
      t.string :rails_view
      t.string :design
      t.integer :inherit_policy

      t.boolean :active, default: true
      t.timestamps
      t.integer :created_by
      t.integer :updated_by

      t.index :name, unique: true
      t.index :alias_for
    end

  end
end
