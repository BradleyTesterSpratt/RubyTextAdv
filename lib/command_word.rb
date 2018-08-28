class CommandWord
  def initialize
    @valid_commands = ["go", "north", "south", "east", "west", "quit", "look", "around", "back", "help", "grab", "drop"] #, "at", "use", "on" 
  end

  attr_reader :valid_commands

  def call(input_string)
    bool = false
    valid_commands.each do |command| 
      bool = true if command.to_s.downcase == input_string.to_s.downcase
    end
    bool
  end
end
