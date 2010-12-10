#!usr/bin/ruby

class Mirrors < ActiveRecord::Migration
  def self.up
    create_table :mirrors do |t|
      t.column :name, :string, :null => false
      t.column :build_number, :string, :null => false
      t.column :uri, :string, :null => false
      t.column :lease_expires, :datetime, :null => true
    end

    # add an index for the email, username, and validation_token fields
    # as they are used to lookup the user.
    add_index :mirrors, :name, :unique => true
    add_index :mirrors, :uri, :unique => true
    add_index :mirrors, :lease_expires, :unique => false

  end

  def self.down
  	drop_table :mirrors
  end
end
