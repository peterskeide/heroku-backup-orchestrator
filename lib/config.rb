require 'yaml'

module HerokuBackupOrchestrator 
  CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/app.yml")
end