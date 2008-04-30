require 'rubygems'
require 'net/http'
require 'open-uri'
require 'json'

module ActiveRecord
  module ConnectionAdapters

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
      def initialize(host='localhost', port=9090)
        @host = host
        @port = port
      end

      ##
      # Executes a SQL query
      def sql_query(sql)
        dbslay_results = cmd_execute(:db, 'SQL' => sql)
        
        case dbslay_results
        when Hash
          DbslayerResult.new(dbslay_results['RESULT'])
        when Array
          dbslay_results.map { |r| DbslayerResult.new(r['RESULT']) }
        else  
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
          @client_version = cmd_execute(:db, 'CLIENT_VERSION' => true)["CLIENT_VERSION"]
        end
        @client_version
      end

      def server_version_num
        if @server_version.nil?
          @server_version = cmd_execute(:db, 'SERVER_VERSION' => true)["SERVER_VERSION"]
        end
        @server_version
      end

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
    end
  end
end