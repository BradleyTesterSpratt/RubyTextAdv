require_relative 'item_holder'

class Player

	def initialize(name)
		@name = name
		@bag = ItemHolder.new(20) 
	end

	attr_reader :bag, :name
	
end