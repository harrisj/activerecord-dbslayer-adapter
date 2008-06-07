require File.dirname(__FILE__) + '/helper.rb'

CITY_HASH_ROWS = [{'id' => 123, 'city_name' => "Mumbai (Bombay)", "country_name" => "India" , 'population' => 10500000},
{'id' => 4112, 'city_name' => "Seoul" , "country_name" =>"South Korea" , 'population' => 9981619} ,
            {'id' => 2433, 'city_name' => "São Paulo" , "country_name" =>"Brazil" , 'population' => 9968485} , 
            {'id' => 554, 'city_name' => "Shanghai" , "country_name" =>"China" , 'population' => 9696300} , 
            {'id' => 332, 'city_name' => "Jakarta" , "country_name" => "Indonesia" , 'population' => 9604900} , 
            {'id' => 3322, 'city_name' => "Karachi" , "country_name" => "Pakistan" , 'population' => 9269265} , 
            {'id' => 644, 'city_name' => "Istanbul" ,"country_name" => "Turkey" , 'population' => 8787958} , 
            {'id' => 12, 'city_name' => "Ciudad de México" , "country_name" => "Mexico" , 'population' => 8591309} , 
            {'id' => 8899, 'city_name' => "Moscow" , "country_name" => "Russian Federation" ,'population' =>  8389200} , 
            {'id' => 1, 'city_name' => "New York" , "country_name" => "United States" ,'population' =>  8008278}]
            
class Test_ActiveRecord_ConnectionAdapters_DbslayerResults < Test::Unit::TestCase
  include ActiveRecord::ConnectionAdapters
  
  def setup
    @result = ActiveRecord::ConnectionAdapters::DbslayerResult.new(CITY_RESULTS["RESULT"])
  end
  
  def test_rows
    assert_equal CITY_ROWS, @result.rows
  end
  
  def test_header
    assert_equal CITY_HEADER, @result.header
  end
  
  def test_types
    assert_equal CITY_TYPES, @result.types
  end
  
  def test_success?
    assert !@result.success?
  end
  
  def test_num_rows_nil
    @result = ActiveRecord::ConnectionAdapters::DbslayerResult.new({})
    assert_equal 0, @result.num_rows
  end
  
  def test_num_rows
    assert_equal 10, @result.num_rows
  end
  
  def test_hash_rows
    assert_equal CITY_HASH_ROWS, @result.hash_rows
  end
  
  def test_each
    output = []
    @result.each do |r|
      output << r
    end
    
    assert_equal CITY_ROWS, output
  end
  
  def test_each_hash
    output = []
    @result.each_hash do |h|
      output << h
    end
    
    assert_equal CITY_HASH_ROWS, output
  end
end

class Test_ActiveRecord_ConnectionAdapters_DbslayerResults_Insert < Test::Unit::TestCase
  include ActiveRecord::ConnectionAdapters
  
  def setup
    @result = ActiveRecord::ConnectionAdapters::DbslayerResult.new(INSERT_ID_RESULT["RESULT"])
  end
  
  def test_success?
    assert @result.success?
  end
  
  def test_affected_rows
    assert_equal 1, @result.affected_rows
  end
  
  def test_insert_id
    assert_equal 1, @result.insert_id
  end
end