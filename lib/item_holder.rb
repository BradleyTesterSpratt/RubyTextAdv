require_relative 'item'

class ItemHolder
	def initialize(capacity)
		@capacity = capacity
		@contents = []
		@current_weight = 0
	end

	attr_reader :contents

	def add_item(item)
		if item.is_a? Item  
			if check_capacity(item.weight)
				@contents << item 
				@current_weight = @current_weight + item.weight
				return true
			else
				return false
			end
		end
	end

	def remove_item(item)
		@current_weight = @current_weight - item.weight
		@contents.delete(item) if item.class == Item
	end

	def check_capacity(weight)
		if weight+@current_weight <= @capacity
			return true
		end 
	end

	def display_contents
		array = []
		@contents.each do |item|
			array << "#{item.name}(#{item.weight})"
		end
		return array
	end

end

