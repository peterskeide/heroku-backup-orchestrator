module HerokuBackupOrchestrator
  class EmailErrorReporter
    def initialize
      smtp_options = {
        :address        => 'smtp.sendgrid.net',
        :port           => '25',
        :authentication => :plain,
        :user_name      => ENV['SENDGRID_USERNAME'],
        :password       => ENV['SENDGRID_PASSWORD'],
        :domain         => ENV['SENDGRID_DOMAIN']
      }
      Pony.options = {
        :from => CONFIG['error_email'], :to => CONFIG['error_email'],
        :via => 'smtp', :via_options => smtp_options,
        :subject => 'BACKUP ERROR'
      }
    end
    
    def report(error)
      body = %{
        An error occurred during backup: #{error.inspect}
        
        The message was:
        
        #{error.message}
      }
      Pony.mail(:body => body)
    end
  end 
end