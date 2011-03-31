class S3BackupTest < Test::Unit::TestCase
  include HerokuBackupOrchestrator
  
  def test_should_return_size_in_megabytes_when_over_1_mb
    backup = create_backup(:content_length => 15000000)
    assert_equal("14.3051", backup.size_mb)
  end
  
  def test_should_return_size_in_megabytes_when_under_1_mb
    backup = create_backup(:content_length => 900000)
    assert_equal("0.8583", backup.size_mb)
  end
  
  def test_should_report_backup_is_a_bundle
    backup = create_backup(:key => "bucket/hbo/app/2010-07-03.tar.gz")
    assert_equal("bundle", backup.type)
  end
  
  def test_should_report_backup_is_a_pgdump
    backup = create_backup(:key => "bucket/hbo/app/2010-07-03.dump")
    assert_equal("pgdump", backup.type)
  end
  
  def test_should_parse_date_from_backup_key
    backup = create_backup(:key => "bucket/hbo/app/2010-07-03.dump")
    assert_equal(Date.new(2010, 7, 3), backup.date)
  end
  
  def test_should_sort_by_date
    backup1 = create_backup(:key => "bucket/hbo/app/2010-07-02.dump")
    backup2 = create_backup(:key => "bucket/hbo/app/2010-07-03.dump")
    backup3 = create_backup(:key => "bucket/hbo/app/2010-07-04.dump")
    backups = [backup3, backup2, backup1]
    assert_equal([backup1, backup2, backup3], backups.sort)
  end
  
  def test_should_delegate_to_s3_object
    content_length = 1500
    content_type = "binary"
    key = "bucket/hbo/app/2010-07-03.dump"
    value = "lots of data"
    
    backup = create_backup(
      :key => key,
      :content_length => content_length,
      :content_type => content_type,
      :value => value
    )
    
    assert_equal(key, backup.key)
    assert_equal(content_length, backup.content_length)
    assert_equal(content_type, backup.content_type)
    assert_equal(value, backup.value)
  end
  
  def create_backup(stub_options)
    s3_obj = stub(stub_options)
    S3Backup.new("appname", s3_obj)
  end
  
end