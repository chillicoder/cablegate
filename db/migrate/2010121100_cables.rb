#!usr/bin/ruby

class Cables < ActiveRecord::Migration
  def self.up
    create_table :cables do |t|
      t.column :reference_id, :string, :null => false
      t.column :subject, :string, :null => false
      t.column :text, :text, :null => false
      t.column :created, :datetime, :null => false
      t.column :released, :datetime, :null => false
      t.column :classification, :string, :null => false
      t.column :origin, :string, :null => false
      t.column :target, :string, :null => false
      t.column :file_path, :string, :null => false
      t.column :tags, :string, :null => false
      
    end

    # add an index for the email, username, and validation_token fields
    # as they are used to lookup the user.
    add_index :cables, :reference_id, :unique => true
    add_index :cables, :file_path, :unique => true
    add_index :cables, :created, :unique => false
    add_index :cables, :released, :unique => false
    add_index :cables, :origin, :unique => false
    add_index :cables, :target, :unique => false
    add_index :cables, :tags, :unique => false
    add_index :cables, :classification, :unique => false

  end

  def self.down
  	drop_table :cables
  end
end
