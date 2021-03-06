require 'yaml'
require 'date'
require 'aws/s3'
require 'forwardable'
require 'heroku'
require 'pgbackups/client'
require 'date'
require 'logger'
require 'pony'

# @author Peter Skeide
module HerokuBackupOrchestrator
  CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/app.yml")
  
  class BackupError < StandardError; end
end

# Require HBO code after reading configuration to ensure config is available at class/module load time
require './lib/heroku_backup_orchestrator/heroku.rb'
require './lib/heroku_backup_orchestrator/amazon_s3.rb'
require './lib/heroku_backup_orchestrator/error_reporter.rb'
require './lib/heroku_backup_orchestrator/backup.rb'