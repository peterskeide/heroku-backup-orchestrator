require 'lib/backup.rb' # Also loads rubygems, aws/s3, yaml and configuration
require 'sinatra/base'
require 'json'

module HerokuBackupOrchestrator
  class Webapp < Sinatra::Base   
    set :root,   File.dirname(__FILE__)
    set :public, File.expand_path(File.dirname(__FILE__) + '/public')
    set :views,  File.expand_path(File.dirname(__FILE__) + '/views')

    set :heroku_app, HerokuBackupOrchestrator::CONFIG['heroku']['app']
    set :s3_key,     HerokuBackupOrchestrator::CONFIG['s3']['key']
    set :s3_secret,  HerokuBackupOrchestrator::CONFIG['s3']['secret']
    set :s3_bucket,  HerokuBackupOrchestrator::CONFIG['s3']['bucket']
    set :users,      YAML.load_file('config/users.yml')['users']

    use Rack::Auth::Basic do |username, password|
      if users.map { |user| user['name'] == username && user['password'] == password }.size >= 1
        true
      else
        false
      end
    end
    
    def users
      settings.users
    end
    
    helpers do      
      def s3(&block)
        AWS::S3::Base.establish_connection!(:access_key_id => settings.s3_key,:secret_access_key => settings.s3_secret) unless AWS::S3::Base.connected?
        block.call
      end
      
      def load_backups
        s3 { AWS::S3::Bucket.find(settings.s3_bucket, :prefix => "heroku_backup_orchestrator/#{settings.heroku_app}/") }
      end
      
      def load_backup_by_name(name)
        s3 { AWS::S3::S3Object.find(name, settings.s3_bucket) }
      end
    end
  
    get '/' do
      @backups = load_backups
      erb :index
    end
  
    get %r{(heroku_backup_orchestrator\/\w+\/\d{4}-\d{2}-\d{2}.tar.gz)} do
      bundle = load_backup_by_name(params[:captures].first)
      attachment(bundle.key)
      content_type(bundle.content_type)
      bundle.value
    end
    
    post '/' do
      content_type :json
      begin
        backup_service = BackupService.new
        backup_service.backup
        {:status => 'success'}.to_json
      rescue BackupError
        {:status => 'error', :message => $!.message }.to_json
      end
    end
  end
end