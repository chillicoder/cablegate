#!usr/bin/ruby
require 'active_record'
require 'time'

class Mirror < ActiveRecord::Base

  def to_json(*a)
    {
      'json_class'   => self.class.name,
      'data'         => { :name => self.uri, :uri => self.uri, :build_number => self.build_number, }
    }.to_json(*a)
  end

  def self.json_create(o)
    new(*o['data'])
  end

end

######################### CLASS LEVEL METHODS ################################

def expired_mirrors
  return Mirror.find(:all, :conditions => ["lease_expires < ?", Time.now])
end

def active_mirrors
  return Mirror.find(:all, :conditions => ["lease_expires > ? OR lease_expires is null", Time.now])
end

public :expired_mirrors, :active_mirrors
