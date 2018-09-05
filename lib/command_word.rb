class CommandWord
  def initialize
    @valid_commands = ["go", "north", "south", "east", "west", "quit", "look", "around", "back", "help", "grab", "drop", "use", "at"] #, "on" 
  end

  attr_reader :valid_commands

  def call(input)
      valid_commands.include?(input.to_s.downcase)
  end
end
