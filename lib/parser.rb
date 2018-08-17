require_relative 'command_word'

class Parser
	def initalize 
		@word_list = []
	end

	def call(string)
		@word_list = string.split(" ").uniq
		valid = false
		if @word_list.length <= 2 
			@word_list.each do |word|
				valid = false if !CommandWord.new.call(word.to_s)
			end
			valid = true
		end
		valid
	end

	def retrieve
		@word_list
	end

end
