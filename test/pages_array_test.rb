class PaginatableArrayTest < Test::Unit::TestCase
  include HerokuBackupOrchestrator
  
  def test_should_have_default_pages_size_of_10
    pages = PaginateableArray.new
    assert_equal(10, pages.page_size)
  end
  
  def test_should_return_number_of_pages
    pages = PaginateableArray.new
    assert_equal(0, pages.nr_of_pages)
    
    data = (1..5).to_a
    pages = PaginateableArray.new(data)
    assert_equal(1, pages.nr_of_pages)
    
    data = (1..10).to_a
    pages = PaginateableArray.new(data)
    assert_equal(1, pages.nr_of_pages)
    
    data = (1..15).to_a
    pages = PaginateableArray.new(data)
    assert_equal(2, pages.nr_of_pages)
    
    data = (1..20).to_a
    pages = PaginateableArray.new(data)
    assert_equal(2, pages.nr_of_pages)
  end
  
  def test_should_return_requested_page
    data = (1..30).to_a
    pages = PaginateableArray.new(data)
    assert_equal((1..10).to_a, pages.page(1))
    assert_equal((11..20).to_a, pages.page(2))
    assert_equal((21..30).to_a, pages.page(3))
  end
  
  def test_should_return_first_page_as_default
    data = (1..20).to_a
    pages = PaginateableArray.new(data)
    assert_equal((1..10).to_a, pages.page)
  end
  
  def test_should_say_if_given_page_is_last_page
    data = (1..20).to_a
    pages = PaginateableArray.new(data)
    assert(!pages.last_page?(1))
    assert(pages.last_page?(2))
  end
end