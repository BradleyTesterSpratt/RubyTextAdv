class CombinableItem < Item
  def initialize(name, weight, use_with, desc = nil)
    super(name, weight, desc)
    @use_with = use_with
    @type = 'combine'
  end

  attr_reader :use_with
end