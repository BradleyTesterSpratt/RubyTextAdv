class Item
  
  def initialize(name, weight, desc = nil)
    @name = name
    desc.nil? ? @desc = "it is a #{name}" : @desc = desc
    @weight = weight
    @type = 'static'
  end

  attr_reader :name, :weight, :desc, :type

end