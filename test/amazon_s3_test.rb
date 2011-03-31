class AmazonS3Test < Test::Unit::TestCase
  include HerokuBackupOrchestrator
  include AWS::S3
  
  def setup
    CONFIG['s3'] = {'key' => 'testkey', 'secret' => 'testsecret', 'bucket' => 'testbucket'}
    @s3 = AmazonS3.new
  end
  
  # Context: load_backups
 
  def test_should_call_bucket_find_with_bucket_name_and_options_Hash
    Bucket.expects(:find).with('testbucket', has_entry(:prefix => "heroku_backup_orchestrator/testapp/"))
    @s3.load_backups("testapp")
  end
  
  def test_should_return_paginateable_array
    Bucket.expects(:find).with(anything, anything).returns(nil)
    result = @s3.load_backups("testapp")
    assert(result.is_a?(PaginateableArray))
  end
  
  def test_should_return_emtpy_array_if_bucket_not_found
    Bucket.expects(:find).with(anything, anything).returns(nil)
    result = @s3.load_backups("testapp")
    assert(result.empty?)
  end
  
  def test_should_return_emtpy_array_if_buckets_objects_is_nil
    bucket = stub(:objects => nil)
    Bucket.expects(:find).with(anything, anything).returns(bucket)
    result = @s3.load_backups("testapp")
    assert(result.empty?)
  end
  
  def test_should_return_emtpy_array_if_bucket_contains_no_objects
    bucket = stub(:objects => [])
    Bucket.expects(:find).with(anything, anything).returns(bucket)
    result = @s3.load_backups("testapp")
    assert(result.empty?)
  end
    
  def test_should_return_array_of_S3Backup_instances
    bucket_returns_stubbed_s3_objects_for_dates("2010-07-02", "2010-07-03", "2010-07-04")
    result = @s3.load_backups("testapp")   
    assert_equal(3, result.size)
    result.each { |obj| assert(obj.is_a?(S3Backup)) }
  end
  
  def test_should_sort_returned_S3Backup_instances_in_reverse_order
    bucket_returns_stubbed_s3_objects_for_dates("2010-07-02", "2010-07-03", "2010-07-04")    
    result = @s3.load_backups("testapp")
    assert_equal(Date.new(2010, 7, 4), result[0].date)
    assert_equal(Date.new(2010, 7, 3), result[1].date)
    assert_equal(Date.new(2010, 7, 2), result[2].date)
  end
  
  private
  
  def bucket_returns_stubbed_s3_objects_for_dates(*date_strings)
    stubs = date_strings.map { |date_str| stub(:key => "bucket/hbo/app/#{date_str}.dump") }
    bucket = stub(:objects => stubs)
    Bucket.expects(:find).with(anything, anything).returns(bucket)
  end
end