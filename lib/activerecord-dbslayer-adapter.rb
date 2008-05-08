# Stole this code from Nick Sieger
begin
  tried_gem ||= false
  require 'active_record/version'
rescue LoadError
  raise if tried_gem
  require 'rubygems'
  gem 'activerecord'
  tried_gem = true
  retry
end

if ActiveRecord::VERSION::MAJOR < 2
  if defined?(RAILS_CONNECTION_ADAPTERS)
    RAILS_CONNECTION_ADAPTERS << %q(dbslayer)
  else
    RAILS_CONNECTION_ADAPTERS = %w(dbslayer)
  end
  if ActiveRecord::VERSION::MAJOR == 1 && ActiveRecord::VERSION::MINOR == 14
    require 'active_record/connection_adapters/dbslayer_adapter'
  end
else
  require 'active_record'
  require 'active_record/connection_adapters/dbslayer_adapter'
end

module ActiveRecord
  module ConnectionAdapters
    class DbslayerAdapter
      VERSION = '0.2.5'
    end
  end
end