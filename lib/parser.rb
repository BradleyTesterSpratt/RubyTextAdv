require_relative 'command_word'

class Parser
  def call(string)

    #return hash commands => [], params => use .each_with_object

    commands = []
    params = []
    string.downcase.split(" ").each { |word| CommandWord.new.call(word.to_s) ? commands << word : params << word }
    return [commands.uniq,params]

    # parsed_words = Hash.new ( { commands: [], params: [] } )
    # string.downcase.split(' ').uniq.each_with_object({}) do |word|
    #   CommandWord.new.call(word.to_s) ? parsed_words[:commands] < word : parsed_words[:params] < word
    # end
  end
end
