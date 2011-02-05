# @author Peter Skeide
module HerokuBackupOrchestrator  
  class HerokuBackup
    # @param [String] application_name The name of the Heroku application that was backed up
    # @param [String] url The (temporary) public_url where the backup file can be accessed
    def initialize(application_name, url)
      @application_name = application_name
      @id = create_id(application_name)
      @url = url
      @type = "pgdump"
    end
        
    attr_reader :id, :url, :type, :application_name
    
    private
    
    def create_id(application_name)
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
      raise BackupError, 'Please add the (free) PGBackups addon before using Heroku Backup Orchestrator with your application' unless authenticated_url
      @client = PGBackups::Client.new(authenticated_url)
    end
    
    def self.application_names
      CONFIG['heroku'].keys
    end
    
    def self.find_by_name(name)
      CONFIG['heroku'].each_key do |app|
        return HerokuApplication.new(CONFIG['heroku'][app]['user'], CONFIG['heroku'][app]['password'], app) if name == app
      end
      nil
    end
    
    def self.all
      apps = []
      CONFIG['heroku'].each do |app, config|
        apps << HerokuApplication.new(CONFIG['heroku'][app]['user'], CONFIG['heroku'][app]['password'], app)
      end
      apps
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
end