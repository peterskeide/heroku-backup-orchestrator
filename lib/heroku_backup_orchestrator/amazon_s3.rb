# @author Peter Skeide
module HerokuBackupOrchestrator
  class S3Backup
    extend Forwardable
    
    MEGABYTE = 1024.0**2
    
    def initialize(application_name, s3_object)
      @s3_object = s3_object
      @application_name = application_name
    end
    
    attr_reader :application_name
    def_delegators :@s3_object, :content_type, :content_length, :value, :key
    
    def size_mb
      @size_mb ||= "%.4f" % (@s3_object.content_length.to_i / MEGABYTE)
    end
    
    def type
      @type ||= @s3_object.key.match(/tar.gz\z/) ? "bundle" : "pgdump"
    end
    
    def date
      @date ||= begin
        date_str = @s3_object.key.match(/\d{4}-\d{2}-\d{2}/).to_s
        Date.strptime(date_str)
      end
    end
    
    def <=>(other)
      self.date <=> other.date
    end 
  end
  
  class PaginateableArray < Array
    def nr_of_pages
      modulo = size % page_size
      modulo == 0 ? (size / page_size) : (size / page_size) + 1
    end
    
    def page_size
      @page_size ||= 10
    end
    attr_writer :page_size
    
    def page(page = 1)
      start_index = (page - 1) * page_size
      slice(start_index, page_size)
    end
    
    def last_page?(page)
      page == nr_of_pages
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
      S3Object.store(backup.id, open(backup.url), @bucket)
      Base.disconnect!
    end
    
    # @param [String] application_name The name of the application whose backups you want to list
    # @return [Array<S3Backup>] Complete list of backups for the given application 
    def load_backups(application_name)
      connected do
        opts = { :prefix => "heroku_backup_orchestrator/#{application_name}/" }
        bucket = Bucket.find(@bucket, opts)
        backups = []
        if bucket
          objects = bucket.objects(opts)
          if objects && !objects.empty?
            objects.each do |obj|
              backups << S3Backup.new(application_name, obj)
            end
          end
        end
        PaginateableArray.new(backups.sort.reverse)
      end  
    end
    
    # @param [String] application_name The name of the application you want to retrieve the backup from
    # @param [String] date The date of the backup (dd-mm-yyyy) 
    # @param [Symbol] type The type of backup you are requesting. Valid values are :pgdump (default) and :bundle
    # @return [S3Backup, nil] A single S3Backup or nil if no matching object is found
    def load_backup(application_name, date, type = :pgdump)
      connected do
        begin
          backup_name = "heroku_backup_orchestrator/#{application_name}/#{basename(date, type)}"
          object = S3Object.find(backup_name, @bucket)
          S3Backup.new(application_name, object)
        rescue NoSuchKey
          nil
        end
      end
    end
    
    private

    def basename(date, type)
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
end