require_relative 'item'
require_relative 'door_switch'
require_relative 'key'
require_relative 'combinable_item'

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
    @contents.delete(item) if item.is_a? Item
  end

  def check_capacity(weight)
    weight + @current_weight <= @capacity
  end

  def display_contents
    array = []
    @contents.each do |item|
      array << "#{item.name}(#{item.weight})"
    end
    return array
  end

end

