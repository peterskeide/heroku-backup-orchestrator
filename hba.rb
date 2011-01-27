require 'lib/backup.rb' # Also loads rubygems, aws/s3, yaml and configuration
require 'sinatra/base'
require 'json'

module HerokuBackupOrchestrator
  class Webapp < Sinatra::Base   
    set :root,   File.dirname(__FILE__)
    set :public, File.expand_path(File.dirname(__FILE__) + '/public')
    set :views,  File.expand_path(File.dirname(__FILE__) + '/views')

    set :heroku_app, HerokuBackupOrchestrator::CONFIG['heroku']['app']
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
      def amazon_s3(&block)
        @amazon_s3 ||= AmazonS3.new
      end
      
      def link_from_key(key)
        date = key.match(/\d{2}-\d{2}-\d{4}/)
        type = key.match(/tar.gz\z/) ? "bundle" : "pgdump"
        "/downloads/#{settings.heroku_app}/#{date}/#{type}"
      end
    end
  
    get '/' do
      @backups = amazon_s3.load_backups(settings.heroku_app)
      erb :index
    end
    
    get '/downloads/:application_name/:date/:type' do
      backup = amazon_s3.load_backup(params[:application_name], params[:date], params[:type].to_sym)
      attachment(backup.key)
      content_type(backup.content_type)
      response['Content-Length'] = backup.content_length
      backup.value
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