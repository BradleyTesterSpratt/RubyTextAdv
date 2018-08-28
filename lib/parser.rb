require_relative 'command_word'

class Parser
  def initialize 
    @word_list = []
  end

  def call(string)
    @commands = []
    @params = []
    @word_list = string.split(" ").uniq
    true if CommandWord.new.call(@word_list[0].to_s)
  end

  def retrieve
    @word_list.each do |word|
      if CommandWord.new.call(word.to_s)
        @commands << word
      else
        @params<< word
      end 
    end
    [@commands,@params]
  end

end
