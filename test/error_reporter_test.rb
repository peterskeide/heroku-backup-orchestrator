class ErrorReporterTest < Test::Unit::TestCase
  include HerokuBackupOrchestrator
  
  def test_should_return_instance_of_EmailErrorReporter_if_sendgrid_configured
    ENV['SENDGRID_USERNAME'] = 'testusername'
    reporter = ErrorReporter.new
    assert(reporter.is_a? EmailErrorReporter)
  end
  
  def test_should_return_instance_of_LogErrorReporter_if_sendgrid_not_available
    CONFIG.delete('sendgrid')
    reporter = ErrorReporter.new
    assert(reporter.is_a? LogErrorReporter)
  end
  
  def test_should_return_instance_of_LogErrorReporter_if_sendgrid_not_properly_configured
    CONFIG['sendgrid'] = nil
    reporter = ErrorReporter.new
    assert(reporter.is_a? LogErrorReporter)
  end 
end