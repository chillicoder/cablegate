#!usr/bin/ruby
require 'active_record'
require 'time'
require 'nokogiri'

class Cable < ActiveRecord::Base

  def to_json(*a)
    {
      'json_class'   => self.class.name,
      'data'         => { :reference_id => self.reference_id,
                          :subject => self.subject,
                          :text => self.text,
                          :created => self.created,
                          :released => self.released,
                          :classification => self.classification,
                          :origin => self.origin,
                          :target => self.target,
                          :tags => self.tags,
                          :file_path => self.file_path
                           }
    }.to_json(*a)
  end

  def self.json_create(o)
    new(*o['data'])
  end

end

######################### CLASS LEVEL METHODS ################################

def parse_from_file(cable_file)
  # load the cable
  doc = Nokogiri::HTML(cable_file)
  raise "No such file: #{cable_file.path}" if doc == nil
#  puts "Parsing file #{cable_file.path}"
  
  # all the content is in a div with the class 'pane big'
  cable_div = doc.at_css('div.big')
  raise "Cable file has no div with class big" if cable_div == nil
  # extract the subject from the first h3 in that div
  head = cable_div.css('h3').first.content
  # the heading will be something like
  # Viewing cable 66BUENOSAIRES2481, EXTENDED NATIONAL JURISDICTIONS OVER HIGH SEAS
  # extract the subject by removing everything up to the ', '
  subject = head[head.index(',')+1..head.length]
  subject = '' if subject == nil
  
  # extract the text,
  text_codes = cable_div.css('code')
  text = text_codes[1].at_css('pre').content
#  puts "Found text"
  
  # extract the reference_id
  table = cable_div.at_css('table')
#  puts "Found table"
  
  rows = table.css('a')
  refid = rows[0].content
#  puts "ref id = #{refid}"
  
  # extract the created date,
  created = rows[1].content
#  puts "created = #{created}"
  
  # extract the released date , 
  released = rows[2].content
#  puts "released = #{released}"
  
  # extract the classification, 
  classification = rows[3].content
#  puts "classification = #{classification}"

  # extract the origin, 
  origin = rows[4].content
#  puts "origin = #{origin}"
  
  # extract the target, 
  target = text_codes[0].at_css('pre').content
#  puts "Found the target"
  # extract the tags

  puts "Cable #{refid}: #{subject}: Classification #{classification}"

  cable = Cable.find_by_reference_id(refid)
  if cable != nil
    puts "cable is already in the database"
    #cable.destroy
  else
    # save the cable
    cable = Cable.create(:reference_id => refid, :subject => subject,
                      :text => text, :created => Time.parse(created).utc, :released => Time.parse(released).utc, :classification => classification,
                      :origin => origin, :target => target, :tags => '', :file_path => cable_file.path)
  end
  #return the saved cable
  return cable
end

public :parse_from_file
