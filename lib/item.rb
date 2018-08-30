class Item
  
  def initialize(name, weight, desc = name, use_with = nil)
    @name = name
    @desc = desc
    @weight = weight
    @use_with = use_with
  end

  attr_reader :name, :weight, :desc, :use_with

end
