require File.dirname(__FILE__) + '/helper.rb'

class TestDbslayerConnection < Test::Unit::TestCase

  STAT_REPLY = {
    "STAT" => "THIS IS A STAT REPLY"
  }.freeze
  
  CLIENT_INFO_REPLY = {
    "CLIENT_INFO" => "5.2.27"
  }.freeze
  
  def setup
    @slayer = ActiveRecord::ConnectionAdapters::DbslayerConnection.new
  end
  
  def test_sql_query
    sql_command = "select * from cities limit 10"
    @slayer.stubs(:cmd_execute).with(:db, {"SQL" => sql_command}).returns(CITY_RESULTS)
    reply = @slayer.sql_query(sql_command)

    assert_not_nil reply.types
    assert_not_nil reply.header
    assert_not_nil reply.rows
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
end
