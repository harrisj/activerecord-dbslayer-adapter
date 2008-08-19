= activerecord_dbslayer_adapter

Jacob Harris
jharris@nytimes.com

== DESCRIPTION:

An ActiveRecord adapter for using the DBSlayer proxy/pooling layer. This allows you to proxy and pool connections to the MySQL backend without worrying about scaling up the front instances more than MySQL is configured to handle (the dreaded Too Many Connections error). Of course, you can also reconfigure master/slave instances on the fly in DBSlayer without having to reconfigure or restart your Rails applications. 

This adapter is really just a judicious subclassing of functionality in the MySQL adapter, so the documented methods might seem very sparse (I only have to override what's changed). Mainly, I swapped it out to execute queries as JSON-over-HTTP calls to DBSlayer rather than using the MySQL connection library. 

== MAJOR CAVEATS:

DBSlayer is a stateless pooling layer. This allows it to easily scale (why do you think HTTP is stateless?), but there are certain database techniques that will have to be abandoned or modified if you use it. The main problem is that each MySQL statement may execute on a different connection (and sometimes on different servers if you've set up transparent slave pooling), so you can not assume the context of one statement is available to the next.

This becomes a problem with transactions. Although DBSlayer can support transactions if you use semicolons to include them all as one statement like
  BEGIN TRANSACTION; more SQL; COMMIT TRANSACTION
There is no readily apparent way to do that via ActiveRecord's block construction (all the adapter has are begin_transaction, commit_transaction methods). So for the moment, transactions do not throw errors but they don't actually use SQL transactions either. Sorry about that. In addition, disabling referential integrity for a connection is not allowed.

The biggest problem is that Rails sets a connection variable for all MySQL connections in order to fix an error selecting null IDs (http://dev.rubyonrails.org/ticket/6778). Since DBSlayer is stateless, this fix doesn't work, but there unfortunately also doesn't seem to be a database or server setting you can alter instead. As a result, the following types of queries WILL return unexpected results when using the DBSlayer adapter:

	Restaurant.find(:all, :conditions => 'id IS NULL')
	
The problem only occurs when searching for null autoincrement primary key columns (not other columns). With the regular MySQL adapter, this would return records with an id value (normally errors). With the DBSlayer adapter, it returns the last inserted item into the table (this is the default MySQL behavior). Luckily, this is not a common idiom in Rails, but you should be aware if you attempt to use it for finding errors in your tables.

== TO DO:

* Return stats from DBSlayer's MYSQL stats => ActiveRecord
* Figure out if there is any way I could support Rails' block-based transaction scheme
* More tests
* Better documentation

== SYNOPSIS:

In your databases.yml

  production:
    adapter: dbslayer
    host: localhost
    port: 9090

All of the other normal database setting like the MySQL server, username, password, etc. are specified in the dbslayer daemon's configuration. 

== REQUIREMENTS:

* the JSON gem
* A running DBSlayer instance

== INSTALL:

* gem install activerecord-dbslayer-adapter
* in your rails project, add the following line at the end of config/environment.rb
  Rails::Initializer.run do |config|
    ...
  
    require 'activerecord-dbslayer-adapter'
 end

== LICENSE:

(The MIT License)

Copyright (c) 2008 The New York Times

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.