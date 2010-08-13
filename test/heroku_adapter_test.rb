require "#{File.dirname(__FILE__)}/../lib/heroku_adapter.rb"

class HerokuAdapterTest < Test::Unit::TestCase
  include HerokuBackupOrchestrator
  
  def setup
    @user = "testuser"
    @password = "testpassword"
    @app = "testapp"
    @client = stub_everything
    Heroku::Client.expects(:new).with(@user, @password).returns(@client)
    HerokuBackupOrchestrator::CONFIG.clear
    HerokuBackupOrchestrator::CONFIG.merge!({ 'heroku' => { 'user' => @user, 'password' => @password, 'app' => @app }})
    @adapter = HerokuAdapter.new
  end
  
  def test_should_find_current_bundle_name_if_bundle_captured
    bundles = [{:name => '2010-07-25'}]
    @client.expects(:bundles).with(@app).returns(bundles)
    assert_equal(bundles.first[:name], @adapter.current_bundle_name)
  end
  
  def test_should_return_nil_if_no_bundle_exists
    @client.expects(:bundles).with(@app).returns([])
    assert_nil(@adapter.current_bundle_name)
  end
  
  def test_should_destroy_existing_bundle
    name = '2010-07-25'
    @client.expects(:bundle_destroy).with(@app, name)
    @adapter.destroy_bundle(name)
  end
  
  def test_should_capture_new_bundle
    url = 'http://someUrl'
    name = '2010-07-25'
    incomplete_capture = [:name => name, :state => 'capturing']
    complete_capture = [:name => name, :state => 'complete']
    @client.expects(:bundle_capture).with(@app)
    @client.expects(:bundles).times(3).with(@app).returns(incomplete_capture, incomplete_capture, complete_capture)
    @adapter.stubs(:sleep).times(2).with(5)
    @client.expects(:bundle_url).with(@app).returns(url)
    bundle_info = @adapter.capture_bundle
    assert_equal(name, bundle_info[:name])
    assert_equal(url, bundle_info[:url])
  end
end