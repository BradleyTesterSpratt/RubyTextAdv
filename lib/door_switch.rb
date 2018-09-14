class DoorSwitch < Item

  def initialize(name, weight, neighbor_name, neighbor_direction, desc = nil)
    @name = name
    @weight = weight
    @type = 'switch'
    desc.nil? ? @desc = "it is a #{name}" : @desc = desc
    @neighbor_name = neighbor_name
    @neighbor_direction = neighbor_direction
  end

  attr_reader :neighbor_name, :neighbor_direction
end