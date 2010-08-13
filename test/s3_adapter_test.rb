require "#{File.dirname(__FILE__)}/../lib/s3_adapter.rb"

class S3AdapterTest < Test::Unit::TestCase
  include HerokuBackupOrchestrator
  
  def setup
    @key = "testkey"
    @secret = "testsecret"
    @bucket = "testbucket"
    @app = "testapp"
    HerokuBackupOrchestrator::CONFIG.clear
    HerokuBackupOrchestrator::CONFIG.merge!({ 'heroku' => { 'app' => @app }, 
                                              's3' => { 'key' => @key, 'secret' => @secret, 'bucket' => @bucket }})
    @adapter = S3Adapter.new
  end
  
  def test_should_upload_bundle_to_amazon_s3
    bundle_info = {:name => '2010-07-26', :url => 'http://tempAmazonS3Url'}
    io = mock
    AWS::S3::Base.expects(:establish_connection!).with(:access_key_id => @key, :secret_access_key => @secret)
    @adapter.stubs(:open).with(bundle_info[:url]).returns(io)
    AWS::S3::S3Object.expects(:store).with('heroku_backup_orchestrator/testapp/2010-07-26.tar.gz', io, @bucket)
    AWS::S3::Base.expects(:disconnect!)
    @adapter.upload_bundle(bundle_info)
  end
end
