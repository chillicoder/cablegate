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
        puts "announcing to other mirrors."
        mirrors = Mirror.active_mirrors
        mirrors.each do |m|
          if m.uri == @me.uri
            puts "No need to announce to myself"
          else
            # announce self to m
            puts "announcing to #{m.name} at #{m.uri}"
            path = "/announcement"
            req = Net::HTTP::Post.new(path, initheader = {'Content-Type' =>'application/json'})
            req.body = { :name => @me.name, :uri => @me.uri, :build_number => @me.build_number}.to_json
            response = Net::HTTP.new(m.uri).start {|http| http.request(req) }
        
            # debugging
            puts "Response #{response.code} #{response.message}: #{response.body}"
          end
        end
      end
    end

  end

  helpers MirrorHelpers

end
