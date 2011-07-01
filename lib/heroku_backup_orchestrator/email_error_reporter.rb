module HerokuBackupOrchestrator
  class EmailErrorReporter   
    
    Pony.options = {
      :from => CONFIG['sendgrid']['from_email'], :to => CONFIG['sendgrid']['to_email'],
      :subject => 'BACKUP ERROR', :via => :smtp, :via_options => {
        :address        => 'smtp.sendgrid.net',
        :port           => '25',
        :authentication => :plain,
        :user_name      => ENV['SENDGRID_USERNAME'],
        :password       => ENV['SENDGRID_PASSWORD'],
        :domain         => ENV['SENDGRID_DOMAIN']
      }    
    }

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