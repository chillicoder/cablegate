#!usr/bin/ruby

require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/r18n'
require 'net/http'
require 'json'
require 'time'

module Sinatra
  module MirrorHelpers

    def locale_available?(locale_code)
      r18n.available_locales.each do |locl|
        return true if locale_code == locl.code
      end
      return false
    end

    def know_thyself!(uri, build_number)
      @me = Mirror.find_by_name('self')
      @me = Mirror.find_by_uri(uri) if @me == nil
      if @me == nil
        @me = Mirror.create(:name => 'self', :uri => uri, :build_number => build_number)
        @me.lease_expires = Time.now.advance(:seconds => 3600)
        @me.save!
      else  # avoids the need to run rake db:seed each time
        if @me.build_number != build_number
          @me.build_number = build_number
          @me.save!
        end
      end
      return @me
    end

    def announce!
      if !too_soon?
        which_mirrors.each do |m|
          handle_announce(announce(m)) unless m.uri == @me.uri
        end
      end
    end

    # when did we last do an announce?
    def too_soon?
      return true if @me == nil #who am I anyway?
      return true if @last_announce_time == nil || (@last_announce_time < Time.now - 1800)
      @last_announce_time = Time.now
    end
    
    # return at most 24 mirrors
    # todo: adjust this if needs be
    def which_mirrors
      mirrors = Mirror.all
      mirrors.delete(@me)
      return mirrors if mirrors.size < 25

      mirrors = Mirror.expired_mirrors
      mirrors += Mirror.active_mirrors
      mirrors.delete(@me)
      mirrors = mirrors.slice(0,24)
      return mirrors
    end
    
    # returns the HTTP Response.
    def announce(mirror)
      puts "Posting announcement to #{mirror.uri}/announcement"
      req = Net::HTTP::Post.new('/announcement', initheader = {'Content-Type' =>'application/json'})
      req.body = { :uri => @me.uri, :build_number => @me.build_number}.to_json
      uri = URI.parse(mirror.uri)
      response = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
      return response
    end
    
    def handle_announce(response)
      if response == nil || response.code != '200'
        puts "Got Bad Response Code #{response.code} #{response.message}: #{response.body}"
        # remove the mirror from our list
        puts "Removing #{m.uri} from the Mirrors list."
        m.destroy
      else
        r = JSON.parse response.body
        bn = r['build_number']
        if bn !=  nil
          if bn == m.build_number
            puts "#{m.uri} responded okay and the build numbers match"
          else
            puts "#{m.uri} responded okay but with a different build number, #{bn}"
            m.build_number = bn
          end
          m.lease_expires = Time.now + 3600
          m.save!
        else
          puts "#{m.uri} responded with a non fatal error: #{r['error']}"
        end
      end
    end
  end

  helpers MirrorHelpers

end
