require "#{File.dirname(__FILE__)}/../lib/backup.rb"
require "#{File.dirname(__FILE__)}/../lib/heroku_adapter.rb"
require "#{File.dirname(__FILE__)}/../lib/s3_adapter.rb"

class BackupTest < Test::Unit::TestCase
  include HerokuBackupOrchestrator
  
  def setup    
    @heroku_adapter = stub_everything
    @s3_adapter = stub_everything
    config = {'heroku' => {}, 's3' => {} }
    HerokuAdapter.expects(:new).returns(@heroku_adapter)
    S3Adapter.expects(:new).returns(@s3_adapter)
    @backup_handler = BackupHandler.new
  end
  
  def test_should_destroy_existing_bundles_if_exists
    name = '2010-07-25'
    @heroku_adapter.expects(:current_bundle_name).returns(name)
    @heroku_adapter.expects(:destroy_bundle).with(name)
    @backup_handler.backup
  end
  
  def test_should_not_destroy_bundle_if_no_bundle_exists
    @heroku_adapter.expects(:current_bundle_name).returns(nil)
    @heroku_adapter.expects(:destroy_bundle).with(anything).never
    @backup_handler.backup
  end
  
  def test_should_capture_new_bundle
    @heroku_adapter.expects(:capture_bundle)
    @backup_handler.backup
  end
  
  def test_should_upload_captured_bundle_to_amazon_s3
    bundle_info = {:name => '2010-07-26', :url => 'http://someTemporaryAmazonS3Url'}
    @heroku_adapter.expects(:capture_bundle).returns(bundle_info)
    @s3_adapter.expects(:upload_bundle).with(bundle_info)
    @backup_handler.backup
  end
  
  def test_should_raise_BackupFailedError_if_an_error_occurs_duing_backup
    @heroku_adapter.expects(:current_bundle_name).raises(Exception)
    assert_raise(BackupFailedError) { @backup_handler.backup }
  end 
  
end