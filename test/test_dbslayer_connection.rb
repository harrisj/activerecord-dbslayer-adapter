require File.dirname(__FILE__) + '/helper.rb'

class TestDbslayerConnection < Test::Unit::TestCase

  def setup
    @slayer = ActiveRecord::ConnectionAdapters::DbslayerConnection.new
  end
  
  def test_query_string
    query = {"foo" => "bar"}
    assert_equal URI.encode(query.to_json), @slayer.send('query_string', query)
  end
  
  # def cmd_execute(endpoint, commands)
  # 147         url = "http://#{host}:#{port}/#{endpoint.to_s}?#{query_string(commands)}"
  # 148         open(url) do |file|
  # 149           JSON.parse(file.read)
  # 150         end
  
  # def test_cmd_execute_url
  #   query = {"SQL" => "select * from cities"}
  #   test = ActiveRecord::ConnectionAdapters::DbslayerConnection.new('localhost', 9090)
  #   URI.expects(:open).with("http://localhost:9090/db?#{test.send(:query_string, query)}")
  #   test.send :cmd_execute, :db, query 
  # end
  
  def test_sql_query
    sql_command = "select * from cities limit 10"
    @slayer.stubs(:cmd_execute).with(:db, {"SQL" => sql_command}).returns(CITY_RESULTS)
    reply = @slayer.sql_query(sql_command)

    assert_not_nil reply.types
    assert_not_nil reply.header
    assert_not_nil reply.rows
  end
  
  def test_sql_null_return
    sql_command = "update set posted = 1"
    @slayer.stubs(:cmd_execute).with(:db, {"SQL" => sql_command}).returns(NULL_RESULT)
    
    status = @slayer.sql_query(sql_command)
    assert_equal true, status
  end
  
  def test_multiple_results
    sql_command = "select * from cities limit 10; select * from countries limit 3"
    @slayer.stubs(:cmd_execute).with(:db, {"SQL" => sql_command}).returns(MULTIPLE_RESULTS)
    
    reply = @slayer.sql_query(sql_command)
    assert_kind_of Array, reply
    assert_equal 2, reply.size
    reply.each {|i| assert_kind_of(ActiveRecord::ConnectionAdapters::DbslayerResult, i)}
    assert_equal CITY_ROWS, reply[0].rows
    assert_equal COUNTRY_ROWS, reply[1].rows
  end
  
  def test_stat
    @slayer.stubs(:cmd_execute).with(:db, {"STAT" => true}).returns(STAT_REPLY)
    reply = @slayer.mysql_stats
    
    assert_equal STAT_REPLY["STAT"], reply
  end
  
  def test_client_info
    @slayer.stubs(:cmd_execute).with(:db, {"CLIENT_INFO" => true}).returns(CLIENT_INFO_REPLY)
    reply = @slayer.client_info
    
    assert_equal CLIENT_INFO_REPLY['CLIENT_INFO'], reply
  end
  
  def test_server_error
    @slayer.stubs(:cmd_execute).returns(ERROR_REPLY)
    assert_raise(ActiveRecord::ConnectionAdapters::DbslayerException) { @slayer.sql_query("SELECT * FROM items") }
  end
  
  def test_client_num
    @slayer.stubs(:cmd_execute).with(:db, {"CLIENT_VERSION" => true}).returns(VERSION_NUM_REPLY)
    reply = @slayer.client_version_num
  
    assert_equal 50037, reply
  end
  
  def test_server_num
    @slayer.stubs(:cmd_execute).with(:db, {"SERVER_VERSION" => true}).returns(VERSION_NUM_REPLY)
    reply = @slayer.server_version_num
  
    assert_equal 50037, reply
  end   
  
end
