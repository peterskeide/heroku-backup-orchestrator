require 'rubygems'
require 'heroku'
require 'pgbackups/client'
require 'date'
require 'aws/s3'
require 'logger'
require 'yaml'

# @author Peter Skeide
module HerokuBackupOrchestrator
  
  CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/app.yml")
  
  class BackupError < StandardError; end
  
  class HerokuBackup
    # @param [String] application_name The name of the Heroku application that was backed up
    # @param [String] url The (temporary) public_url where the backup file can be accessed
    def initialize(application_name, url)
      @filename = create_filename(application_name)
      @url = url
    end
    
    attr_reader :filename, :url
    
    private
    
    def create_filename(application_name)
      "heroku_backup_orchestrator/#{application_name}/#{Date.today.strftime('%d-%m-%Y')}.dump"
    end
  end
  
  class HerokuApplication
    # @param [String] user The username required to log in to the application
    # @param [String] password The password required to log into the application
    # @param [String] application_name The name of the heroku application
    # @raise [BackupError] A BackupError will be raised if the pgbackups addon is not added to the application
    def initialize(user, password, application_name)
      @application_name = application_name
      heroku = Heroku::Client.new(user, password)
      config_vars = heroku.config_vars(application_name)
      @from_name = 'DATABASE_URL'
      @from_url = config_vars[@from_name]
      authenticated_url = config_vars['PGBACKUPS_URL']
      raise BackupError, 'Please add the (free) PGBackups addon before using the Heroku Backup Orchestrator' unless authenticated_url
      @client = PGBackups::Client.new(authenticated_url)
    end
    
    # Creates a new backup (pgdump) of a Heroku application. 
    # Will expire the exiting backup (same as --expire from the heroku command line tool).
    #  
    # @raise [BackupError] A BackupError will be raised if the backup fails for some reason
    # @return [HerokuBackup] The newly created backup
    def create_backup
      backup = @client.create_transfer(@from_url, @from_name, nil, 'BACKUP', :expire => true)
      raise BackupError, 'Heroku indicated something went wrong with the backup. Please investigate.' if backup['errors']
      while true
        break if backup['finished_at']
        sleep 5
        backup = @client.get_transfer(backup['id'])
      end
      HerokuBackup.new(@application_name, backup['public_url'])
    end
    
    def to_s
      @application_name
    end
  end
  
  class AmazonS3
    include ::AWS::S3
    
    def initialize
      @key = CONFIG['s3']['key']
      @secret = CONFIG['s3']['secret']
      @bucket = CONFIG['s3']['bucket']
    end
     
    # Upload backup to Amazon S3
    # 
    # @param [HerokuBackup] backup The backup to upload to Amazon S3    
    def upload(backup)
      connect
      S3Object.store(backup.filename, open(backup.url), @bucket)
      Base.disconnect!
    end
    
    # @param [String] application_name The name of the application whose backups you want to list
    # @return [Array<S3Object>] Complete list of backups for the given application 
    def load_backups(application_name)
      connected do
        opts = { :prefix => "heroku_backup_orchestrator/#{application_name}/" }
        bucket = Bucket.find(@bucket, opts)
        bucket ? bucket.objects(opts) : []
      end  
    end
    
    # @param [String] application_name The name of the application you want to retrieve the backup from
    # @param [String] date The date of the backup (dd-mm-yyyy) 
    # @param [Symbol] type The type of backup you are requesting. Valid values are :pgdump (default) and :bundle
    # @return [S3Object, nil] A single S3Object or nil if no matching object is found
    def load_backup(application_name, date, type = :pgdump)
      connected do
        begin
          backup_name = "heroku_backup_orchestrator/#{application_name}/#{backup_name(date, type)}"
          S3Object.find(backup_name, @bucket)
        rescue NoSuchKey
          nil
        end
      end
    end
    
    private
    
    def backup_name(date, type)
      case type
      when :bundle
        backup = "#{date}.tar.gz"
      when :pgdump
        backup = "#{date}.dump"
      else raise "Illegal backup type: #{type}"
      end
    end
    
    def connected
      raise "No block given" unless block_given?
      connect unless Base.connected?   
      yield
    end
    
    def connect
      Base.establish_connection!(:access_key_id => @key, :secret_access_key => @secret, :use_ssl => true)
    end
  end

  class BackupService   
    def backup
      applications.each do |app|
        begin
          log.debug("Backing up #{app} ...")
          backup = app.create_backup
          log.debug("Uploading to Amazon S3")
          amazon_s3.upload(backup)
          log.debug("Backup finished successfully")
        rescue BackupError => e
          log.error("Backup failed: #{$!.message}")
        end
      end
    end
    
    private
    
    def applications
      heroku_app = HerokuApplication.new(CONFIG['heroku']['user'], CONFIG['heroku']['password'], CONFIG['heroku']['app'])
      [heroku_app] 
    end
    
    def amazon_s3
      @amazon_s3 ||= AmazonS3.new
    end
    
    def log
      @log ||= Logger.new(STDERR)
    end
  end
end