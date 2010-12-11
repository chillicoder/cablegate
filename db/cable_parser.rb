#!usr/bin/ruby

require 'active_record'
require 'models/cable'
require 'time'

puts "Setting Timezone to UTC"
Time.zone = :utc
ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.default_timezone = :utc

cables_folder = File.join(File.dirname(__FILE__), '../public/cable')

raise "No cables found in #{cables_folder}" unless File.directory? cables_folder
Dir.glob("public/cable/**") do |yyyy|
  # for each year get a month
  Dir.glob("#{yyyy}/**") do |mm|
    # in each month folder here is a cable ref.html file
    Dir.glob("#{mm}/**.html") do |cref|
      Cable.parse_from_file(File.open(cref))
    end
  end
end
