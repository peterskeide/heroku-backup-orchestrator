class HerokuBackupTest < Test::Unit::TestCase
  include HerokuBackupOrchestrator
  
  def setup
    @backup = HerokuBackup.new("testapp", "http://test.url")
  end
  
  def test_should_create_id_based_on_application_name_and_todays_date   
    assert_equal("heroku_backup_orchestrator/testapp/#{Date.today}.dump", @backup.id)
  end
  
  def test_should_set_default_type_of_new_backup_to_pgdump
    assert_equal("pgdump", @backup.type)
  end
  
end