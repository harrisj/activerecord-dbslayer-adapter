require 'rubygems'
require 'active_support'
require 'active_record'
require 'test/unit'
require 'mocha'

$:.unshift(File.join(File.dirname(__FILE__), %w[.. lib]))

require 'active_record/connection_adapters/dbslayer_adapter'

STAT_REPLY = {"STAT" => "STAT"}

# Let's mock out the DBSlayer reply
CITY_ROWS = [[123, "Mumbai (Bombay)" , "India" , 10500000] ,
            [4112, "Seoul" , "South Korea" , 9981619] ,
            [2433, "São Paulo" , "Brazil" , 9968485] , 
            [554, "Shanghai" , "China" , 9696300] , 
            [332, "Jakarta" , "Indonesia" , 9604900] , 
            [3322, "Karachi" , "Pakistan" , 9269265] , 
            [644, "Istanbul" , "Turkey" , 8787958] , 
            [12, "Ciudad de México" , "Mexico" , 8591309] , 
            [8899, "Moscow" , "Russian Federation" , 8389200] , 
            [1, "New York" , "United States" , 8008278]
           ].freeze

CITY_TYPES = ["MYSQL_TYPE_STRING", "MYSQL_TYPE_STRING" , "MYSQL_TYPE_LONG"].freeze

CITY_HEADER = ["id", "city_name" , "country_name" , "population"].freeze
   
CITY_RESULTS = {
  "RESULT" => {"TYPES" =>  CITY_TYPES, 
              "HEADER" =>  CITY_HEADER, 
              "ROWS" => CITY_ROWS
              }
}.freeze


SHOW_TABLES_REPLY = {"RESULT"=> {"HEADER"=> ["Tables_in_Test_Database"], 
                     "ROWS" => [["table1"], ["table2"]], 
                     "TYPES"=>["MYSQL_TYPE_VAR_STRING"]},
                     "SERVER"=>"test-slave"}.freeze
                     
SHOW_KEYS_REPLY = {"RESULT" => {"HEADER" => ["Table", "Non_unique", "Key_name", "Seq_in_index", "Column_name", "Collation", "Cardinality", "Sub_part", "Packed", "Null", "Index_type", "Comment"], 
                                "ROWS"=>[["places", 0, "PRIMARY", 1, "id", "A", 0, nil, nil, "", "BTREE", ""], 
                                         ["places", 0, "md5hash", 1, "md5hash", "A", nil, nil, nil, "YES", "BTREE", ""],
                                         ["places", 1, "terms", 1, "terms", nil, nil, nil, nil, "YES", "FULLTEXT", ""]], 
                                "TYPES"=>["MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_LONGLONG", "MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_LONGLONG", "MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_LONGLONG", "MYSQL_TYPE_LONGLONG", "MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_VAR_STRING"]}, 
                   "SERVER"=>"test-slave"}.freeze

SHOW_COLUMNS_REPLY = {"RESULT" => {"HEADER"=>["Field", "Type", "Null", "Key", "Default", "Extra"], 
                                   "ROWS"=>[["id", "int(10)", "NO", "PRI", nil, "auto_increment"],
                                            ["zipcode", "varchar(5)", "NO", "", "", ""],
                                            ["terms", "varchar(255)", "YES", "MUL", nil, ""],
                                            ["md5hash", "varbinary(16)", "YES", "UNI", nil, ""]], 
                                    "TYPES"=>["MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_BLOB", "MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_BLOB", "MYSQL_TYPE_VAR_STRING"]}, 
                      "SERVER"=>"test-slave"}.freeze
                      
DESCRIBE_REPLY = {"RESULT" => {"HEADER"=>["Field", "Type", "Null", "Key", "Default", "Extra"], 
                               "ROWS"=>[["id", "int(10)", "NO", "PRI", nil, "auto_increment"], 
                                        ["zipcode", "varchar(5)", "NO", "", "", ""],
                                        ["terms", "varchar(255)", "YES", "MUL", nil, ""], 
                                        ["md5hash", "varbinary(16)", "YES", "UNI", nil, ""]], 
                                "TYPES"=>["MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_BLOB", "MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_BLOB", "MYSQL_TYPE_VAR_STRING"]}, 
                  "SERVER"=>"test-slave"}.freeze

VARIABLE_REPLY = {"RESULT" => {"HEADER"=> ["Variable_name", "Value"], 
                               "ROWS"=>[["character_set_database", "utf8"]], 
                              "TYPES"=>["MYSQL_TYPE_VAR_STRING", "MYSQL_TYPE_VAR_STRING"]}, 
                  "SERVER"=>"test-slave"}.freeze 

                     
def sql_hash(sql)
  {"SQL" => sql}.freeze
end                      
                      