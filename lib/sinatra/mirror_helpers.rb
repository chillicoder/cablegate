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
        @me.lease_expires = nil # own lease never expires.
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
          handle_announce(announce(m),m) unless m.uri == @me.uri # don't announce to self
        end
      end
    end

    # when did we last do an announce?
    # todo: for some reason  @last_announce_time is always nil
    def too_soon?
      if @me == nil
        puts "Who am I?"
        return true
      end
      if @last_announce_time == nil
        puts "We have not announced to anyone yet. Go For it."
        @last_announce_time = Time.now.utc
        puts "Last announce time is now #{@last_announce_time.strftime('%Y-%m-%dT%H:%M:%SZ')}"
        return false
      end
      if  @last_announce_time < (Time.now - 1800).utc
        puts "Yes it's time to announce. Last announce time was #{@last_announce_time.strftime('%Y-%m-%dT%H:%M:%SZ')}"
        @last_announce_time = Time.now.utc
        return false
      end
      puts "Not time yet. Last announce time was #{@last_announce_time.strftime('%Y-%m-%dT%H:%M:%SZ')}"
      return true
    end
    
    # return at most 24 mirrors
    def which_mirrors
      # first load all mirrors except me
      mirrors = Mirror.all
      mirrors.delete(@me)
      return mirrors if mirrors.size < 25

      # otherwise load the expired mirrors, add to that list the acive mirror except me and pick the first 24
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
    
    def handle_announce(response, m)
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
        else
          puts "#{m.uri} responded with a non fatal error: #{r['error']}"
        end
        # update the lease time anyway, even if we got a non-fatal error response.
        lx = (Time.now + 3600).utc
        m.lease_expires = lx
        m.save!
        puts "Lease expiry for #{m.uri} now set to #{lx.strftime('%Y-%m-%dT%H:%M:%SZ')}"
      end
    end
  end

  helpers MirrorHelpers

end
