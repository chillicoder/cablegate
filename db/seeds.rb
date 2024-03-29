#!usr/bin/ruby

require 'active_record'
require 'models/mirror'
require 'time'

puts "Setting Timezone to UTC"
Time.zone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.default_timezone = :utc

mirror = Mirror.find_by_name("default")
if mirror != nil
  puts "Deleting previous default mirror."
  mirror.destroy
end

puts "Seeding database with default mirror"

mirror = Mirror.create( :name => "default", :uri => "http://cablegate.heroku.com", :build_number => "not supplied")
mirror.save!

# add any other seeding here.
