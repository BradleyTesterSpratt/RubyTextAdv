class DoorSwitch < Item

  def initialize(name, weight, neighbor_name, neighbor_direction, desc = nil)
    super(name, weight, desc)
    @neighbor_name = neighbor_name
    @neighbor_direction = neighbor_direction
    @type = 'switch'
    @active = true
  end

  attr_reader :neighbor_name, :neighbor_direction, :active

  def use_switch
    @active = false
  end
end