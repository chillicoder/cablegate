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
      end
      return @me
    end

    def announce!
      if @me == nil
        puts "I know not myself, and thus can't announce yet. Awaiting an incoming request to tell me where I am."
      else
        puts "Announcing myself to active mirrors."
        mirrors = Mirror.active_mirrors
        mirrors.each do |m|
          if m.uri == @me.uri
            puts "No need to announce to myself"
          else
            # announce self to m
            puts "Posting announcement to #{m.uri}/announcement"
            path = "/announcement"
            req = Net::HTTP::Post.new(path, initheader = {'Content-Type' =>'application/json'})
            # note @me.name is 'self' which is not useful for sending to other mirrors.  In this case just use the uri as the name.
            req.body = { :name => @me.uri, :uri => @me.uri, :build_number => @me.build_number}.to_json
            uri = URI.parse(m.uri)
            response = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }

            # debugging
            puts "Response #{response.code} #{response.message}: #{response.body}"
            
            # assuming the result is json like {:lease_time} just parse it and remember to get back to the mirror later
          end
        end
      end
    end

  end

  helpers MirrorHelpers

end
