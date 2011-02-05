# @author Peter Skeide
module HerokuBackupOrchestrator
  class BackupService
    def backup_app(heroku_app)
      log.debug("Backing up #{heroku_app} ...")
      backup = heroku_app.create_backup
      log.debug("Uploading to Amazon S3")
      amazon_s3.upload(backup)
      log.debug("Backup finished successfully")
    end
    
    def backup_all
      HerokuApplication.all.each do |app|
        begin
          backup_app(app)
        rescue BackupError => e
          log.error("Backup failed: #{$!.message}")
        end
      end
    end
    
    private

    def amazon_s3
      @amazon_s3 ||= AmazonS3.new
    end
    
    def log
      @log ||= Logger.new(STDERR)
    end
  end
end