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

require 'sinatra/mirror_helpers'

class Cablegate < Sinatra::Base
  enable  :sessions
  set :root, File.dirname(__FILE__)
  set :models, Proc.new { root && File.join(root, 'models') }
  set :build_number, '201012072146'
  
  register Sinatra::R18n
  register Sinatra::Flash

  helpers Sinatra::MirrorHelpers

  @me = nil # need to wait for any incoming request before we know what our host name is.

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
  end

  # if there is a new locale setting in the request then use it.
  before do
    session[:locale] = params[:locale] if params[:locale] #the r18n system will load it automatically
  end
  
######################   ROUTES   #################################

  get '/' do
    flash.now[:message] = "Cablegate Mirror — Build #{options.build_number}"
    @mirrors = Mirror.active_mirrors
    my_uri = "http://#{request.host_with_port}"
    @me = know_thyself!(my_uri, options.build_number)
    haml :index
  end

  get '/announce' do
    flash.now[:tip] = "Announced Self to Mirrors"
    @mirrors = Mirror.active_mirrors
    my_uri = "http://#{request.host_with_port}"
    @me = know_thyself!(my_uri, options.build_number)
    announce!
    haml :index
  end

  post '/announcement' do
    content_type :json
    # handle the incoming announcement
    @@log.debug("Incoming Announcement Request recieved.")
    request.body.rewind # not sure why I have to do this.
    # incoming will be { :name, :uri, :build_number }
    mirror = JSON.parse request.body.read
    return {:error => "Invalid Mirror Data"}.to_json if mirror['name'] == nil || mirror['uri'] == nil || mirror['build_number'] == nil
    @@log.debug("Incoming Mirror data was acceptable.")

    # if incoming mirror uri contains 'localhost' then ignore it.
    # todo: test the incoming URI to ensure it's ok.
    return {:error => "Incoming Mirror #{mirror['uri']} is unreachable."} if mirror['uri'].include?('localhost')
    @@log.debug("Incoming Mirror data was reachable (ie was not localhost).")

    my_uri = "http://#{request.host_with_port}"
    @me = know_thyself!(my_uri, options.build_number)
    return {:error => 'Announced to Self'} if mirror['uri'] == my_uri
    @@log.debug("Not trying to announce to self.")

    # maybe we have already seen this mirror, in which case update the build number if it's changed, and update the lease time
    new_mirror = Mirror.find_by_uri(mirror['uri'])
    if new_mirror == nil
      # add incoming mirror to db and set the lease_time
      new_mirror = Mirror.create( :name => mirror['name'], :uri => mirror['uri'], :build_number => mirror['build_number'])
    else
      # update the build number if it's changed
      new_mirror.build_number = mirror['build_number'] unless new_mirror.build_number == mirror['build_number']
    end
    # update the lease time
    new_mirror.lease_expires = Time.now.advance(:seconds => 3600)
    new_mirror.save!

    @@log.debug("Incoming Mirror #{new_mirror.uri} of build #{new_mirror.build_number} expires at #{new_mirror.lease_expires}")

    return {:lease_time => 3600 }.to_json
  end

end
