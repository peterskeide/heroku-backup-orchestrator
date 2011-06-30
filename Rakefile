desc 'Capture a new bundle for your heroku app and upload it to Amazon S3'
task :cron do
  require './lib/heroku_backup_orchestrator.rb'
  HerokuBackupOrchestrator::BackupService.new.backup_all
end

desc 'Run unit tests'
task :test do
  require './lib/heroku_backup_orchestrator.rb'
  require 'test/unit'
  require 'mocha'
  Dir.glob('test/*_test.rb').each { |file| require File.join('.', file) }
end

desc "The default task will invoke the 'test' task"
task :default do
  Rake::Task['test'].invoke
end