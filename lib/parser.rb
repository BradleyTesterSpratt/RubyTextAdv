require_relative 'command_word'

class Parser
	def initialize 
		@word_list = []
		@commands = []
		@params = []
		#@param_list = []
	end

	# def call(string)
	# 	@word_list = string.split(" ").uniq
	# 	valid = true
	# 	if !CommandWord.new.call(@word_list[0].to_s)
	# 		valid=false
	# 	else
	# 		@word_list.each do |word|
	# 			if !CommandWord.new.call(word.to_s)
	# 				@param_list << word
	# 				#@word_list.delete(word)
	# 			end
	# 		end
	# 	end
	# 	valid
	# end

	def call(string)
		@word_list = string.split(" ").uniq
		valid = true
		if !CommandWord.new.call(@word_list[0].to_s)
			valid=false
		else
	 		@word_list.each do |word|
	 			if CommandWord.new.call(word.to_s)
	 				@commands << word
	 			else
				 	@params<< word
				end	
			end
		end
	end

	def retrieve
		output = [@commands,@params]
	end

		#command = @word_list = string.split(" ").uniq
		#param = @word_list[1..-1].join(" ")
end
