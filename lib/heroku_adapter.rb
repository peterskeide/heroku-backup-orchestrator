require 'heroku'
require "#{File.dirname(__FILE__)}/config.rb"

module HerokuBackupOrchestrator 
  class HerokuAdapter
    
    def initialize
      config = HerokuBackupOrchestrator::CONFIG['heroku']
      heroku_user = config['user']
      heroku_password = config['password']
      @client = Heroku::Client.new(heroku_user, heroku_password)
      @app = config['app']
    end
    
    # The name of the first bundle in the bundles array returned
    # from heroku is returned to the caller. Hence, only the
    # single bundle addon is supported.
    def current_bundle_name
      bundles = @client.bundles(@app)
      if !bundles.empty?
        bundles.first[:name]
      else
        nil
      end
    end
    
    def destroy_bundle(name)
      @client.bundle_destroy(@app, name)
    end
  
    def capture_bundle
      @client.bundle_capture(@app)    
      while((new_bundle = @client.bundles(@app).first)[:state] != 'complete')
        sleep 5
      end    
      new_bundle_url = @client.bundle_url(@app)
      {:url => new_bundle_url, :name => new_bundle[:name]}
    end 
  end
end