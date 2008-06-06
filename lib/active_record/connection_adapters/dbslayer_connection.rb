require 'rubygems'
require 'net/http'
require 'open-uri'
require 'json'

module ActiveRecord
  module ConnectionAdapters

    class DbslayerException < RuntimeError
    end
    
    class DbslayerResult
      def initialize(results_hash)
        @hash = results_hash
      end

      def rows
        @hash['ROWS']
      end

      def types
        @hash['TYPES']
      end

      def header
        @hash['HEADER']
      end
      
      def success?
        @hash['SUCCESS']
      end
      
      def affected_rows
        @hash['AFFECTED_ROWS']
      end
      
      def insert_id
        @hash['INSERT_ID']
      end
      
      ## Compatibility to the MySQL ones
      def num_rows
        return 0 if rows.nil?
        rows.size
      end

      def each
        return if rows.nil?
        rows.each {|r| yield r }
      end
      
      def hash_rows
        return [] if rows.nil?
        rows.map do |row|
          hash = {}
          header.each_with_index do |head, i|
            hash[head] = row[i]
          end
          
          hash
        end
      end
      
      def each_hash
        return if rows.nil?
        hash_rows.each do |row|            
          yield row
        end
      end
    end

    class DbslayerConnection
      attr_reader :host, :port, :insert_id, :affected_rows
      
      def initialize(host='localhost', port=9090)
        @host = host
        @port = port
        @insert_id = nil
        @affected_rows = nil
      end

      ##
      # Executes a SQL query
      def sql_query(sql)
        dbslay_results = cmd_execute(:db, 'SQL' => sql)
                
        # check for an error
        if dbslay_results['MYSQL_ERROR']
          raise DbslayerException, "MySQL Error #{dbslay_results['MYSQL_ERRNO']}: #{dbslay_results['MYSQL_ERROR']}"
        elsif result = dbslay_results['RESULT']
          case result
          when Hash
            out = DbslayerResult.new(result)
            set_affected!(out)
            out
          when Array
            out = result.map {|r| DbslayerResult.new(r) }
            set_affected!(out.last)
            out
          else  
            raise DbslayerException, "Unknown format for SQL results from DBSlayer"
          end
        else  
          raise DbslayerException, "Unknown format for SQL results from DBSlayer"
        end
      end

      alias execute sql_query
      alias query sql_query

      def mysql_stats
        results = cmd_execute(:db, 'STAT' => true)
        results['STAT']
      end

      alias stat mysql_stats

      def client_info
        if @client_info.nil?
          @client_info = cmd_execute(:db, 'CLIENT_INFO' => true)["CLIENT_INFO"]
        end
        @client_info
      end

      alias server_info client_info

      def client_version_num
        if @client_version.nil?
          @client_version = Integer(cmd_execute(:db, 'CLIENT_VERSION' => true)["CLIENT_VERSION"])
        end
        @client_version
      end

      def server_version_num
        if @server_version.nil?
          @server_version = Integer(cmd_execute(:db, 'SERVER_VERSION' => true)["SERVER_VERSION"])
        end
        @server_version
      end

      def escape_string(str)
        str.gsub(/([\0\n\r\032\'\"\\])/) do
          case $1
          when "\0" then "\\0"
          when "\n" then "\\n"
          when "\r" then "\\r"
          when "\032" then "\\Z"
          else "\\"+$1
          end
        end
      end
      alias :quote :escape_string
      
      private 
      def query_string(commands)
        URI.encode commands.to_json
      end

      ##
      # Returns a JSON date
      def cmd_execute(endpoint, commands)
        url = "http://#{host}:#{port}/#{endpoint.to_s}?#{query_string(commands)}"
        open(url) do |file|
          JSON.parse(file.read)
        end
      end
      
      def set_affected!(result)
        @insert_id = result.insert_id
        @affected_rows = result.affected_rows
      end
    end
  end
end