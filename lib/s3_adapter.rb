require 'aws/s3'
require "#{File.dirname(__FILE__)}/config.rb"

module HerokuBackupOrchestrator 
  class S3Adapter
    include AWS::S3
  
    def initialize
      config = HerokuBackupOrchestrator::CONFIG['s3']
      @key = config['key']
      @secret = config['secret']
      @bucket = config['bucket']
      @app = HerokuBackupOrchestrator::CONFIG['heroku']['app']
    end
  
    def upload_bundle(bundle_info)
      Base.establish_connection!(:access_key_id => @key,:secret_access_key => @secret)
      filename = "heroku_backup_orchestrator/#{@app}/#{bundle_info[:name]}.tar.gz"
      S3Object.store(filename, open(bundle_info[:url]), @bucket)
      Base.disconnect!
    end
  
  end
end