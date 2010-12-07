#!usr/bin/ruby

require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/r18n'
require 'sinatra/flash'
require 'active_record'
require 'logger'
require 'pony'
require 'erb'
require 'haml'
require 'json'
require 'time'
require 'net/http'

class Cablegate < Sinatra::Base
  enable  :sessions
  set :root, File.dirname(__FILE__)
  set :models, Proc.new { root && File.join(root, 'models') }
  register Sinatra::R18n
  register Sinatra::Flash

  @active_user = nil         # the active user is reloaded on each request in the before method.

  class << self
    def load_models!
      if !@models_loaded
        raise "No models folder found!" unless File.directory? models
        Dir.glob("models/**.rb") { |m| require m }
        @@log.debug("Models loaded")
        @models_are_loaded = true
      end
    end
  end

  class << self
    def announce!
      @@log.debug("announcing to other mirrors.")
      mirrors = Mirror.active_mirrors
      mirrors.each do |m|
        # announce self to m
        @@log.debug("announcing to #{m.name} at #{m.uri}")
        path = "/announcement"
        req = Net::HTTP::Post.new(path, initheader = {'Content-Type' =>'application/json'})
        req.body = { :name => 'name', :uri => 'http://cablegate.heroku.com', :build_number => '12345test'}.to_json
        response = Net::HTTP.new(m.uri).start {|http| http.request(req) }
        
        # debugging
        @@log.debug("Response #{response.code} #{response.message}: #{response.body}")
      end
    end
  end

  # configuration blocks are called depending on the value of ENV['RACK_ENV] #=> 'test', 'development', or 'production'
  # on Heroku the default rack environment is 'production'.  Locally it's development.
  # if you switch rack environments locally you will need to reseed the database as it uses different databases for each obviously.
  configure :development do
    set :environment, :development
    @@log = Logger.new(STDOUT)
    @@log.level = Logger::DEBUG
    @@log.info("Cablegate Development Mode")

    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::WARN      #not interested in database stuff right now.

    Time.zone = :utc
    ActiveRecord::Base.time_zone_aware_attributes = true
    ActiveRecord::Base.default_timezone = :utc

    dbconfig = YAML.load(File.read('config/database.yml'))
    ActiveRecord::Base.establish_connection dbconfig['development']

    @models_are_loaded = false
    load_models!
    announce!
  end

  configure :production do  
    set :environment, :production
    @@log = Logger.new(STDOUT)  # TODO: should look for a better option than this.
    @@log.level = Logger::DEBUG
    @@log.info("Cablegate running in Production Mode")

    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::WARN

    Time.zone = :utc
    ActiveRecord::Base.time_zone_aware_attributes = true
    ActiveRecord::Base.default_timezone = :utc

    dbconfig = YAML.load(File.read('config/database.yml'))
    ActiveRecord::Base.establish_connection dbconfig['production']

    @models_are_loaded = false
    load_models!
    announce!
  end

  configure :test do  
    set :environment, :test
    @@log = Logger.new(STDOUT)
    @@log.level = Logger::DEBUG
    @@log.info("Testing Cablegate")

    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::WARN      #not interested in database stuff right now.

    Time.zone = :utc
    ActiveRecord::Base.time_zone_aware_attributes = true
    ActiveRecord::Base.default_timezone = :utc

    dbconfig = YAML.load(File.read('config/database.yml'))
    ActiveRecord::Base.establish_connection dbconfig['test']

    @models_are_loaded = false
    load_models!
    announce!
  end

  # if there is a new locale setting in the request then use it.
  before do
    session[:locale] = params[:locale] if params[:locale] #the r18n system will load it automatically
  end
  
######################   ROUTES   #################################

  get '/' do
    flash.now[:message] = "This is a simple Cablegate mirror"
    @mirrors = Mirror.active_mirrors
    my_uri = "http://#{request.host_with_port}"
    @me = Mirror.find_by_uri(my_uri)
    haml :index
  end

  post '/announcement' do
    content_type :json
    # handle the incoming announcement

    request.body.rewind # not sure why I have to do this.
    # incoming will be { :name, :uri, :build_number }
    mirror = JSON.parse request.body.read
    return {:error => "Invalid Mirror Data"}.to_json if mirror['name'] == nil || mirror['uri'] == nil || mirror['build_number'] == nill
    my_uri = "http://#{request.host_with_port}"
    me = Mirror.find_by_uri(my_uri)
    return {:error => 'Announced to Self'} if mirror['uri'] == my_uri
    
    # add incoming mirror to db and set the lease_time
    new_mirror = Mirror.create( :name => mirror['name'], :uri => mirror['uri'], :build_number => mirror['build_number'])
    new_mirror.lease_expires = Time.now.advance(:seconds => 3600)
    new_mirror.save!
    return {:lease_time => 3600 }.to_json
  end

end
