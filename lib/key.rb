class Key < Item
  def initialize(name, weight, door, desc = nil)
    super(name, weight, desc)
    @door = door
    @type = 'key'
  end

  attr_reader :door
end