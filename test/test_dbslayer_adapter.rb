require File.dirname(__FILE__) + '/helper.rb'

class Test_ActiveRecord_ConnectionAdapters_DbslayerAdapter < Test::Unit::TestCase  
  def setup
    @config = { :host => 'localhost', :port => 9090 }
    @adapter = ActiveRecord::Base.dbslayer_connection(@config)
  end
  
  def test_adapter_name
    assert_equal 'DBSlayer (MySQL)', @adapter.adapter_name
  end
  
  def test_active?
    @adapter.raw_connection.expects(:mysql_stats).returns("STAT_REPLY")
    assert @adapter.active?
  end
  
  def test_active_fail?
    
  end
  
  def test_select_rows
    select_query = "select * from cities limit 10"
    select_name = 'foo'
    
    @adapter.raw_connection.expects(:cmd_execute).with(:db, sql_hash(select_query)).returns(CITY_RESULTS)
    rows = @adapter.select_rows(select_query, select_name)
    
    assert_equal CITY_ROWS, rows
  end
  
  def test_insert_sql_with_id
    
  end
  
  def test_insert_sql_no_id
    
  end
  
  def test_tables
    @adapter.raw_connection.expects(:cmd_execute).with(:db, sql_hash("SHOW TABLES")).returns(SHOW_TABLES_REPLY)
    tables = @adapter.tables
    
    assert_equal ["table1", "table2"], tables
  end
  
  def test_columns
    @adapter.raw_connection.expects(:cmd_execute).with(:db, sql_hash("SHOW FIELDS FROM `places`")).returns(SHOW_COLUMNS_REPLY)
    columns = @adapter.columns('places')
    
    assert_equal 4, columns.size
    assert_equal %w(id zipcode terms md5hash), columns.map {|c| c.name }
    columns.each do |c|
      assert_kind_of ActiveRecord::ConnectionAdapters::DbslayerColumn, c
    end
  end
  
  def test_indexes
    @adapter.raw_connection.expects(:cmd_execute).with(:db, sql_hash("SHOW KEYS FROM `places`")).returns(SHOW_KEYS_REPLY)
    indexes = @adapter.indexes('places')
    
    assert_equal 2, indexes.size
    indexes.each do |i|
      assert_kind_of ActiveRecord::ConnectionAdapters::IndexDefinition, i
    end
  end
  
  def test_pk_and_sequence_for
    @adapter.raw_connection.expects(:cmd_execute).with(:db, sql_hash("describe `places`")).returns(DESCRIBE_REPLY)
    assert_equal ['id', nil], @adapter.pk_and_sequence_for('places')
  end
  
  def test_show_variable
    @adapter.raw_connection.expects(:cmd_execute).with(:db, sql_hash("SHOW VARIABLES LIKE 'character_set_database'")).returns(VARIABLE_REPLY)
    variable = @adapter.show_variable('character_set_database')
    assert_equal 'utf8', variable
  end
end
