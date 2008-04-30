require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/connection_adapters/dbslayer_connection'
require 'active_record/connection_adapters/mysql_adapter'

module ActiveRecord
  class Base
    # Establishes a connection to the database that's used by all Active Record objects.
    def self.dbslayer_connection(config) # :nodoc:
      config = config.symbolize_keys
      host     = config[:host]
      port     = config[:port]
      
      connection = ConnectionAdapters::DbslayerConnection.new(host, port)
      ConnectionAdapters::DbslayerAdapter.new(connection, logger, [host, port], config)
    end
  end

  module ConnectionAdapters
    class DbslayerColumn < MysqlColumn #:nodoc:
      # def extract_default(default)
      #   if type == :binary || type == :text
      #     if default.blank?
      #       default
      #     else
      #       raise ArgumentError, "#{type} columns cannot have a default value: #{default.inspect}"
      #     end
      #   elsif missing_default_forged_as_empty_string?(default)
      #     nil
      #   else
      #     super
      #   end
      # end

      private
        def simplified_type(field_type)
          return :boolean if DbslayerAdapter.emulate_booleans && field_type.downcase.index("tinyint(1)")
          return :string  if field_type =~ /enum/i
          super
        end

        # MySQL misreports NOT NULL column default when none is given.
        # We can't detect this for columns which may have a legitimate ''
        # default (string) but we can for others (integer, datetime, boolean,
        # and the rest).
        #
        # Test whether the column has default '', is not null, and is not
        # a type allowing default ''.
        # def missing_default_forged_as_empty_string?(default)
        #   type != :string && !null && default == ''
        # end
    end

    # The DbslayerAdapter is an adapter to use Rails with the DBSlayer
    #
    # Options:
    #
    # * <tt>:host</tt> -- Defaults to localhost
    # * <tt>:port</tt> -- Defaults to 3306
    #
    # Like the MySQL adapter: by default, the MysqlAdapter will consider all columns of type tinyint(1)
    # as boolean. If you wish to disable this emulation (which was the default
    # behavior in versions 0.13.1 and earlier) you can add the following line
    # to your environment.rb file:
    #
    #   ActiveRecord::ConnectionAdapters::DbslayerAdapter.emulate_booleans = false
    class DbslayerAdapter < MysqlAdapter
      VERSION = '0.2.0'

      def initialize(connection, logger, connection_options, config)
        super(connection, logger, connection_options, config)
        ActiveRecord::Base.allow_concurrency = true
      end

      def adapter_name #:nodoc:
        'DBSlayer (MySQL)'
      end

      # def supports_migrations? #:nodoc:
      #   true
      # end
      # 
      # def native_database_types #:nodoc:
      #   {
      #     :primary_key => "int(11) DEFAULT NULL auto_increment PRIMARY KEY",
      #     :string      => { :name => "varchar", :limit => 255 },
      #     :text        => { :name => "text" },
      #     :integer     => { :name => "int", :limit => 11 },
      #     :float       => { :name => "float" },
      #     :decimal     => { :name => "decimal" },
      #     :datetime    => { :name => "datetime" },
      #     :timestamp   => { :name => "datetime" },
      #     :time        => { :name => "time" },
      #     :date        => { :name => "date" },
      #     :binary      => { :name => "blob" },
      #     :boolean     => { :name => "tinyint", :limit => 1 }
      #   }
      # end
      # 
      # 
      # # QUOTING ==================================================
      # 
      # def quote(value, column = nil)
      #   if value.kind_of?(String) && column && column.type == :binary && column.class.respond_to?(:string_to_binary)
      #     s = column.class.string_to_binary(value).unpack("H*")[0]
      #     "x'#{s}'"
      #   elsif value.kind_of?(BigDecimal)
      #     "'#{value.to_s("F")}'"
      #   else
      #     super
      #   end
      # end
      # 
      # def quote_column_name(name) #:nodoc:
      #   "`#{name}`"
      # end
      # 
      # def quote_table_name(name) #:nodoc:
      #   quote_column_name(name).gsub('.', '`.`')
      # end
      # 
      # def quote_string(string) #:nodoc:
      #   @connection.quote(string)
      # end
      # 
      # def quoted_true
      #   "1"
      # end
      # 
      # def quoted_false
      #   "0"
      # end

      # REFERENTIAL INTEGRITY ====================================

      def disable_referential_integrity(&block) #:nodoc:
        #FIXME: I CAN'T LET YOU DO THIS
        # old = select_value("SELECT @@FOREIGN_KEY_CHECKS")
        # 
        # begin
        #   update("SET FOREIGN_KEY_CHECKS = 0")
        #   yield
        # ensure
        #   update("SET FOREIGN_KEY_CHECKS = #{old}")
        # end
      end

      # CONNECTION MANAGEMENT ====================================

      def active?
        stats = @connection.mysql_stats
        !stats.nil? && !stats.empty?
      rescue
        false
      end

      def reconnect!
        # DO NOTHING, we connect on the request
      end

      def disconnect!
        # DO NOTHING, we connect on the request
      end


      # DATABASE STATEMENTS ======================================

      def select_rows(sql, name = nil)
        result = execute(sql, name)
        result.rows
      end

      def execute(sql, name = nil) #:nodoc:
        log(sql, name) { 
          @connection.execute(sql)
        }
      end

      # def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil) #:nodoc:
      #   super sql, name
      #   id_value || @connection.insert_id
      # end
      # 
      # def update_sql(sql, name = nil) #:nodoc:
      #   super
      #   @connection.affected_rows
      # end

      def begin_db_transaction #:nodoc:
        # FIXME: raise exception?
      #   execute "BEGIN"
      # rescue Exception
        # Transactions aren't supported
      end

      def commit_db_transaction #:nodoc:
        # FIXME: raise exception?

      #   execute "COMMIT"
      # rescue Exception
        # Transactions aren't supported
      end

      def rollback_db_transaction #:nodoc:
        # FIXME: raise exception?

      #   execute "ROLLBACK"
      # rescue Exception
        # Transactions aren't supported
      end

      # SCHEMA STATEMENTS ========================================

      # def structure_dump #:nodoc:
      #   if supports_views?
      #     sql = "SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'"
      #   else
      #     sql = "SHOW TABLES"
      #   end
      # 
      #   select_all(sql).inject("") do |structure, table|
      #     table.delete('Table_type')
      #     structure += select_one("SHOW CREATE TABLE #{quote_table_name(table.to_a.first.last)}")["Create Table"] + ";\n\n"
      #   end
      # end
      # 
      # def recreate_database(name) #:nodoc:
      #   drop_database(name)
      #   create_database(name)
      # end

      # Create a new MySQL database with optional :charset and :collation.
      # Charset defaults to utf8.
      #
      # Example:
      #   create_database 'charset_test', :charset => 'latin1', :collation => 'latin1_bin'
      #   create_database 'matt_development'
      #   create_database 'matt_development', :charset => :big5
      # def create_database(name, options = {})
      #   if options[:collation]
      #     execute "CREATE DATABASE `#{name}` DEFAULT CHARACTER SET `#{options[:charset] || 'utf8'}` COLLATE `#{options[:collation]}`"
      #   else
      #     execute "CREATE DATABASE `#{name}` DEFAULT CHARACTER SET `#{options[:charset] || 'utf8'}`"
      #   end
      # end
      # 
      # def drop_database(name) #:nodoc:
      #   execute "DROP DATABASE IF EXISTS `#{name}`"
      # end
      # 
      # def current_database
      #   select_value 'SELECT DATABASE() as db'
      # end

      # Returns the database character set.
      # def charset
      #   if @charset.nil?
      #     @charset = show_variable 'character_set_database'
      #   end
      #   
      #   @charset
      # end
      # 
      # # Returns the database collation strategy.
      # def collation
      #   if @collation.nil?
      #     @collation = show_variable 'collation_database'
      #   end
      #   @collation
      # end

      def tables(name = nil) #:nodoc:
        tables = []
        execute("SHOW TABLES", name).rows.each { |row| tables << row[0] }
        tables
      end

      # def drop_table(table_name, options = {})
      #   super(table_name, options)
      # end

      def indexes(table_name, name = nil)#:nodoc:
        indexes = []
        current_index = nil
        execute("SHOW KEYS FROM #{quote_table_name(table_name)}", name).rows.each do |row|
          if current_index != row[2]
            next if row[2] == "PRIMARY" # skip the primary key
            current_index = row[2]
            indexes << IndexDefinition.new(row[0], row[2], row[1] == "0", [])
          end

          indexes.last.columns << row[4]
        end
        indexes
      end

      def columns(table_name, name = nil)#:nodoc:
        sql = "SHOW FIELDS FROM #{quote_table_name(table_name)}"
        columns = []
        execute(sql, name).rows.each { |row| columns << DbslayerColumn.new(row[0], row[4], row[1], row[2] == "YES") }
        columns
      end

      # def create_table(table_name, options = {}) #:nodoc:
      #   super(table_name, options.reverse_merge(:options => "ENGINE=InnoDB"))
      # end
      # 
      # def rename_table(table_name, new_name)
      #   execute "RENAME TABLE #{quote_table_name(table_name)} TO #{quote_table_name(new_name)}"
      # end
      # 
      # def change_column_default(table_name, column_name, default) #:nodoc:
      #   current_type = select_one("SHOW COLUMNS FROM #{quote_table_name(table_name)} LIKE '#{column_name}'")["Type"]
      # 
      #   execute("ALTER TABLE #{quote_table_name(table_name)} CHANGE #{quote_column_name(column_name)} #{quote_column_name(column_name)} #{current_type} DEFAULT #{quote(default)}")
      # end
      # 
      # def change_column(table_name, column_name, type, options = {}) #:nodoc:
      #   unless options_include_default?(options)
      #     if column = columns(table_name).find { |c| c.name == column_name.to_s }
      #       options[:default] = column.default
      #     else
      #       raise "No such column: #{table_name}.#{column_name}"
      #     end
      #   end
      # 
      #   change_column_sql = "ALTER TABLE #{quote_table_name(table_name)} CHANGE #{quote_column_name(column_name)} #{quote_column_name(column_name)} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
      #   add_column_options!(change_column_sql, options)
      #   execute(change_column_sql)
      # end
      # 
      # def rename_column(table_name, column_name, new_column_name) #:nodoc:
      #   current_type = select_one("SHOW COLUMNS FROM #{quote_table_name(table_name)} LIKE '#{column_name}'")["Type"]
      #   execute "ALTER TABLE #{quote_table_name(table_name)} CHANGE #{quote_column_name(column_name)} #{quote_column_name(new_column_name)} #{current_type}"
      # end
      
      # SHOW VARIABLES LIKE 'name'
      def show_variable(name)
        variables = select_all("SHOW VARIABLES LIKE '#{name}'")
        variables.first['Value'] unless variables.empty?
      end

      # Returns a table's primary key and belonging sequence.
      def pk_and_sequence_for(table) #:nodoc:
        keys = []
        execute("describe #{quote_table_name(table)}").each_hash do |h|
          keys << h["Field"]if h["Key"] == "PRI"
        end
        keys.length == 1 ? [keys.first, nil] : nil
      end

      private
        def connect
          # By default, MySQL 'where id is null' selects the last inserted id.
          # Turn this off. http://dev.rubyonrails.org/ticket/6778
          ##FIXME !!! execute("SET SQL_AUTO_IS_NULL=0")
        end

        def select(sql, name = nil)
          result = execute(sql, name)
          rows = result.hash_rows
          rows
        end

        # Executes the update statement and returns the number of rows affected.
        def update_sql(sql, name = nil)
          execute(sql, name).rows[0][0]
        end
        
        def supports_views?
          ## get mysql version
          version[0] >= 5
        end

        def version
          @version ||= @connection.server_info.scan(/^(\d+)\.(\d+)\.(\d+)/).flatten.map { |v| v.to_i }
        end
    end
  end
end
