require_relative 'item'
require_relative 'item_holder'

class Room
  def initialize(name, description, long_description)
    @name = name
    @description = description
    @long_description = long_description
    @neighbors  = []
    @floor = ItemHolder.new(99999)
  end

  attr_reader :name, :description, :long_description, :neighbors, :floor

  def add_neighbor(room, direction, door=nil)
    neighbors << {name: room, direction: direction, door: door}
  end

  def fill(item)
    @floor.add_item(item)
  end

  def unlock_neighbor(room)
    neighbors.each do |neighbor|
      neighbor[:door] = nil if neighbor[:door] == room[:door]
    end
  end

end