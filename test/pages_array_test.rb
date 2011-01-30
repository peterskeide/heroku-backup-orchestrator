require "#{File.dirname(__FILE__)}/../lib/backup.rb"

class PagesArrayTest < Test::Unit::TestCase
  include HerokuBackupOrchestrator
  
  def test_should_have_default_pages_size_of_10
    pages = PagesArray.new
    assert_equal(10, pages.page_size)
  end
  
  def test_should_return_number_of_pages
    pages = PagesArray.new
    assert_equal(0, pages.nr_of_pages)
    
    data = [1, 2, 3, 4, 5]
    pages = PagesArray.new(data)
    assert_equal(1, pages.nr_of_pages)
    
    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    pages = PagesArray.new(data)
    assert_equal(1, pages.nr_of_pages)
    
    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    pages = PagesArray.new(data)
    assert_equal(2, pages.nr_of_pages)
    
    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    pages = PagesArray.new(data)
    assert_equal(2, pages.nr_of_pages)
  end
  
  def test_should_return_requested_page
    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30]
    pages = PagesArray.new(data)
    assert_equal([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], pages.page(1))
    assert_equal([11, 12, 13, 14, 15, 16, 17, 18, 19, 20], pages.page(2))
    assert_equal([21, 22, 23, 24, 25, 26, 27, 28, 29, 30], pages.page(3))
  end
  
  def test_should_return_firt_page_as_default
    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    pages = PagesArray.new(data)
    assert_equal([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], pages.page)
  end
  
  def test_should_say_if_given_page_is_last_page
    data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    pages = PagesArray.new(data)
    assert(!pages.last_page?(1))
    assert(pages.last_page?(2))
  end
end