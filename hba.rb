require 'lib/heroku_backup_orchestrator.rb'
require 'sinatra/base'
require 'json'

module HerokuBackupOrchestrator
  class Webapp < Sinatra::Base   
    set :root,   File.dirname(__FILE__)
    set :public, File.expand_path(File.dirname(__FILE__) + '/public')
    set :views,  File.expand_path(File.dirname(__FILE__) + '/views')
    set :users,  YAML.load_file('config/users.yml')['users']

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
      def amazon_s3
        @amazon_s3 ||= AmazonS3.new
      end
      
      def backup_service
        @backup_service ||= BackupService.new
      end
      
      def link_to(backup)
        "/applications/#{backup.application_name}/downloads/#{backup.date_str}/#{backup.type}"
      end
      
      def link_to_page(app_name, page_nr, text)
        "<a href='/applications/#{app_name}?page=#{page_nr}'>#{text}</a>"
      end
    end
  
    get '/' do
      @application_names = HerokuApplication.application_names
      erb :index
    end
    
    get '/applications/:application_name' do
      @selected_application = params[:application_name]
      @backups = amazon_s3.load_backups(@selected_application)
      @current_page = params[:page] ? params[:page].to_i : 1
      erb :application
    end
    
    get '/applications/:application_name/downloads/:date/:type' do
      backup = amazon_s3.load_backup(params[:application_name], params[:date], params[:type].to_sym)
      attachment(backup.key)
      content_type(backup.content_type)
      response['Content-Length'] = backup.content_length
      backup.value
    end
  
    post '/applications/:application_name' do
      content_type :json
      begin
        heroku_app = HerokuApplication.find_by_name(params[:application_name])
        backup_service.backup_app(heroku_app)
        {:status => 'success'}.to_json
      rescue BackupError
        {:status => 'error', :message => $!.message }.to_json
      end
    end
  end
end