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
      "heroku_backup_orchestrator/#{application_name}/#{Date.today.strftime('%d-%m-%Y')}-pgdump.tar.gz"
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
    
    # @param [String] key The key required to connect to Amazon S3
    # @param [String] secret The secret key required to connect to Amazon S3
    # @param [String] bucket The name of the bucket where backups will be stored. It must exist!
    def initialize(key, secret, bucket)
      @key, @secret, @bucket = key, secret, bucket
    end
     
    # Upload backup to Amazon S3
    # 
    # @param [HerokuBackup] backup The backup to upload to Amazon S3    
    def upload(backup)
      Base.establish_connection!(:access_key_id => @key, :secret_access_key => @secret)   
      S3Object.store(backup.filename, open(backup.url), @bucket)
      Base.disconnect!
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
      @amazon_s3 ||= AmazonS3.new(CONFIG['s3']['key'], CONFIG['s3']['secret'], CONFIG['s3']['bucket'])
    end
    
    def log
      @log ||= Logger.new(STDERR)
    end
  end
end