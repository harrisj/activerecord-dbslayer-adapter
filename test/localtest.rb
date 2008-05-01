require 'rubygems'
require 'activerecord-dbslayer-adapter'

ActiveRecord::Base.establish_connection({
  :adapter => 'dbslayer',
  :host => 'localhost',
  :port => 9090
})

class Restaurant < ActiveRecord::Base
  has_many :reviews
end

class Review < ActiveRecord::Base
  belongs_to :restaurant
end

rests = Restaurant.find(:all, :limit => 10)

puts rests[0].inspect

size = Restaurant.count(:all)

puts size

caracas = Restaurant.find_by_name('Caracas Arepa Bar')

puts caracas.reviews.first.inspect
