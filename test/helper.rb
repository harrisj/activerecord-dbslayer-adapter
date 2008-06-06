require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_record'
require 'mocha'

$:.unshift(File.join(File.dirname(__FILE__), %w[.. lib]))

require 'active_record/connection_adapters/dbslayer_adapter'

STAT_REPLY = {"STAT" => "STAT"}

CLIENT_INFO_REPLY = {"CLIENT_INFO" => "5.2.27"}

VERSION_NUM_REPLY = {"SERVER_VERSION" => "50037", "CLIENT_VERSION" => "50037"}

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

CITY_TYPES = ["MYSQL_TYPE_INTEGER", "MYSQL_TYPE_STRING", "MYSQL_TYPE_STRING" , "MYSQL_TYPE_LONG"].freeze

CITY_HEADER = ["id", "city_name" , "country_name" , "population"].freeze
   
CITY_RESULTS = {
  "RESULT" => {"TYPES" =>  CITY_TYPES, 
              "HEADER" =>  CITY_HEADER, 
              "ROWS" => CITY_ROWS
              }
}.freeze

COUNTRY_ROWS = [[1, 'United States'], [2, 'Canada'], [3, 'India']].freeze

COUNTRY_TYPES = ["MYSQL_TYPE_INTEGER", "MYSQL_TYPE_STRING"]

COUNTRY_HEADER = ["id", "name"]

MULTIPLE_RESULTS = {
  "RESULT" => [{"TYPES" =>  CITY_TYPES, 
              "HEADER" =>  CITY_HEADER, 
              "ROWS" => CITY_ROWS
              },
              
              {"TYPES" =>  COUNTRY_TYPES, 
               "HEADER" =>  COUNTRY_HEADER, 
               "ROWS" => COUNTRY_ROWS
              }
    
              ]
}.freeze

NULL_RESULT = {"RESULT" => {"SUCCESS" => true}}.freeze

INSERT_ID_RESULT = {"RESULT" => {"AFFECTED_ROWS" => 1 , "INSERT_ID" => 1 , "SUCCESS" => true} , "SERVER" => "dbslayer"}.freeze
                         
UPDATE_RESULT = {"RESULT" => {"AFFECTED_ROWS" => 42 , "SUCCESS" => true} , "SERVER" => "dbslayer"}.freeze

INSERT_THEN_SELECT_RESULT = {"RESULT"=> [{"AFFECTED_ROWS"=>1, "INSERT_ID"=>5, "SUCCESS"=>true}, {"HEADER"=>["id", "name"], "ROWS"=>[[1, "Brooklyn"], [2, "Queens"], [3, "Staten Island"], [4, "Queens"], [5, "Paramus"]], "TYPES"=>["MYSQL_TYPE_LONG", "MYSQL_TYPE_VAR_STRING"]}], "SERVER"=>"dbslayer"}.freeze

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

ERROR_REPLY = {"MYSQL_ERRNO"=>1045, "MYSQL_ERROR"=>"Access denied for user 'harrisj'@'localhost' (using password: NO)", "SERVER"=>"test"}
                     
def sql_hash(sql)
  {"SQL" => sql}.freeze
end                      
                      