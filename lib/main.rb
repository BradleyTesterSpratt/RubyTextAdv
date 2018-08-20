$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib')
require 'parser'
require 'room'
require 'constants'
require 'json'
require 'player'
require 'highline'
require 'tty-box'

class Main
	def initialize
		@map = []
		build_map(Constants::LevelOne)
		@inv_content= ""
		@room_content = ""
		@output_content = ""
	end

	attr_reader :map

	def play
		play=true
		clear
		help
		room_frame
		output_frame
		inv_frame
		print get_string("Enter your name : ","yellow")
		@player=Player.new(gets.chomp)
		@inventory = @player.bag
		@current_location=map[0]
		@previous_location= []
		look
		while play
			clear
			room_frame
			output_frame
			@inv_content= @inventory.contents.empty? ? get_string("Empty","green") : get_string(@inventory.display_contents.join(', ').to_s,"green")
			inv_frame
			valid_input=false
			commands = []
			params = []
	 		while !valid_input
	 			input=get_input("Enter Command : ","yellow")
	 			@parser=Parser.new
	 			if (@parser.call(input))
					valid_input=true
					commands = @parser.retrieve[0]
					params = @parser.retrieve[1]
	 			end
			case 
				when commands[0] == "go"
					case
						when commands[1] == "back" then
								if !@previous_location.empty?
									@current_location = @previous_location.pop
									@output_content = get_string("#{@player.name} returned to #{@current_location.name}","green")
									look
								end
						when commands[1].nil? then 
							@output_content = get_string("You need to give a direction","red")
						else 
							move(commands[1])
					end
				when commands[0] == "look" then
					case
						when commands[1]==nil then look
						when commands[1] == "around" then look_around
					else
						@output_content = get_string("Look at what?","red")
					end
				when commands[0] == "quit"
					print get_string('type "yes" to quit: ',"yellow")
					if (gets.chomp.downcase == "yes")
						play=false
					end
				when commands[0] == "help"
					help
				when commands[0] == "grab"
					grab(params,@current_location.floor)
				when commands[0] == "drop"
					drop(params,@current_location.floor)
				else 
					@output_content = get_string("please enter a valid command","red")
				end
	 		end
	 	end
	 end

	def get_string(string,colour)
		if !HighLine.String(string).respond_to? colour
			colour = "white"
		end
		HighLine.String(string).public_send(colour)
	end 

	def get_input(string,colour)
		print get_string(string,colour)
		gets.chomp
	end

	def look
		@room_content = @current_location.description + "\n"
		@current_location.neighbors.each do |neighbor|	
			#add exit description to json and use that
			@room_content = @room_content + "There is an exit to the #{get_string(neighbor[1],"blue")}\n"
		end
	end

	def help
		@room_content = get_string("Valid commands are:","green") + " \ngo north, go east, go west, go back\nlook, look around, grab\nquit, help"
	end

	def look_around
		@room_content = @current_location.long_description + "\n"
		if !@current_location.floor.contents.empty?
			@current_location.floor.contents.each do |item|
				@room_content = @room_content + "There is a #{get_string(item.name,"green")}\n"
			end
		end
	end

	def move(direction)
		can_move=false
		@current_location.neighbors.each do |neighbor|
			if neighbor[1].downcase == direction
				@map.each do |room|
					if room.name == neighbor[0]
						@previous_location << @current_location
						@room_content = @current_location = room
						look
						@output_content = get_string("#{@player.name} travelled #{direction}","green")
						can_move=true
					end
				end
			end
		end
		if !can_move
			@output_content = get_string("There is nothing in that direction","red") 
		end
	end

	def build_map(json)
		file = File.read(json)
		level_data = JSON.parse(file)

		level_data['Room'].each do |ent|
			room = Room.new(ent['name'], ent['desc'], ent['long_desc'])
			ent['neighbors'].each do |neighbor|
				room.add_neighbor(neighbor['name'], neighbor['direction'])
			end
			if !ent['items'].nil?
				ent['items'].each do |item|
					room.fill(Item.new(item["name"],item["weight"]))
				end
			end
			@map << room
		end
	end

	def room_frame
		box = TTY::Box.frame(
			width: 50, 
			height: 10,  
			border: :thick) do
			@room_content
		end
		print box
	end

	def output_frame
		box = TTY::Box.frame(
			width: 50, 
			height: 3,  
			border: :thick, 
			style: { border: { fg: :yellow } } ) do
			@output_content
		end
		print box
	end

	def inv_frame
		box = TTY::Box.frame(
			width: 50, 
			height: 3,  
			border: :thick, 
			title: {top_left: "INVENTORY"}, 
			style: { border: { fg: :green } } ) do
			@inv_content
		end
		print box
	end

	def grab(params,container)
		if container.contents.empty?
			@output_content = get_string("There are no items","red")
		elsif params.empty?
			print get_string("Enter object to grab: ","yellow")
			item=gets.chomp
		else
			item = params.join(' ').chomp
		end
		if !item.nil?
		found = false 				
			container.contents.each do |valid_item| 
				if item == valid_item.name	
					found = true
					if @inventory.add_item(valid_item)
						container.remove_item(valid_item)
						@output_content = get_string("#{@player.name} picked up the #{item}","green")
					else 
						@output_content = get_string("#{item} is too heavy","red")
					end
				end
			end		
			@output_content = get_string("There is no #{item}","red") if !found
		end
	end


	# def drop(item,container)
 # 		@inventory.contents.each do |valid_item| 
	#  		if item == valid_item.name	
	# 			if container.add_item(valid_item)
	# 				@inventory.remove_item(valid_item)
	# 				@output_content = get_string("#{@player.name} dropped the #{item}","green")
	# 			else
	# 				@output_content = get_string("There is no room on the floor for #{item}","red")
	# 			end
	# 		end
	# 	end
	# end

	def drop (params,container)
		if @inventory.contents.empty?
			@output_content = get_string("#{@player.name} has nothing to drop","red")
		elsif params.empty?
			print get_string("Enter object to drop: ","yellow")
	 		item=gets.chomp
		else
			item = params.join(' ').chomp
		end
		if !item.nil?
			found = false
			@inventory.contents.each do |valid_item| 
		 		if item == valid_item.name
		 		found = true	
					if container.add_item(valid_item)
						@inventory.remove_item(valid_item)
						@output_content = get_string("#{@player.name} dropped the #{item}","green")
					else
						@output_content = get_string("There is no room on the floor for #{item}","red")
					end
				end
			end
			@output_content = get_string("#{@player.name} does not have #{item}","red") if !found 
		end
	end

	def clear
		system("clear")
	end

end


if __FILE__ == $0
	Main.new.play
end
