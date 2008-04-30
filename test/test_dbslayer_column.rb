require File.dirname(__FILE__) + '/helper.rb'

class Test_ActiveRecord_ConnectionAdapters_DbslayerColumn < Test::Unit::TestCase
  def setup
    @column = ActiveRecord::ConnectionAdapters::DbslayerColumn.new('foo', false, 'tinyint(1)')
  end
  
  # the only thing changed from the MySQL one
  def test_boolean_coerce
    ActiveRecord::ConnectionAdapters::DbslayerAdapter.emulate_booleans = true
    assert_equal :boolean, @column.send(:simplified_type, "tinyint(1)")
  end
end