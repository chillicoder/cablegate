#!usr/bin/ruby

require 'active_record'
require 'models/mirror'
require 'time'

puts "Setting Timezone to UTC"
Time.zone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.default_timezone = :utc

puts "Seeding database with Default Mirror"

mirror = Mirror.find_by_name("Default")
if mirror != nil
  mirror.destroy
end
mirror = Mirror.create( :name => "default", :uri => "http://cablegate.heroku.com", :build_number => "201012061721")
mirror.save!

# add any other seeding here.
