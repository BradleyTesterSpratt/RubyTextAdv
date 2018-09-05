class Item
  
  def initialize(name, weight, type = 'static', desc = nil, use_with = nil)
    @name = name
    desc.nil? ? @desc = "it is a #{name}" : @desc = desc
    type.nil? ? @type = 'static' : @type = type
    @weight = weight
    @use_with = use_with
  end

  attr_reader :name, :weight, :desc, :use_with, :type

end
