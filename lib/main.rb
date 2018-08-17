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
		@parser = Parser.new
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
			while !valid_input
				input=get_input("Enter Command : ","yellow")
				if (@parser.call(input))
					valid_input=true
					commands = @parser.retrieve
				end
			end
			case 
				when commands[0] == "go"
					case
						when commands[1] == "back" then
								if !@previous_location.empty?
									@current_location = @previous_location.pop
									look
								end
						when commands[1].nil? then 
							@output_content = get_string("You need to give a direction","red")
						else move(commands[1])
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
				when commands [0] == "grab"
					current_floor = @current_location.floor
					if current_floor.contents.empty?
						@output_content = get_string("There are no items","red")
					else
						print get_string("Enter object to grab: ","yellow")
						item=gets.chomp
						current_floor.contents.each do |valid_item| 
							if item == valid_item.name	
								if @inventory.add_item(valid_item)
									current_floor.remove_item(valid_item)
									@output_content = get_string("#{@player.name} picked up the #{item}","green")
								else
									@output_content = get_string("#{item} is too heavy","red")
								end
							else
								puts "debug"
							end
						end
					end
				when commands[0] == "drop"
					current_floor = @current_location.floor
					if @inventory.contents.empty?
						@output_content = get_string("#{@player.name} has nothing to drop","red")
						else
							print get_string("Enter object to drop: ","yellow")
							item=gets.chomp
							@inventory.contents.each do |valid_item| 
								if item == valid_item.name	
									if current_floor.add_item(valid_item)
										@inventory.remove_item(valid_item)
										@output_content = get_string("#{@player.name} dropped the #{item}","green")
									else
										@output_content = get_string("There is no room on the floor for #{item}","red")
									end
								end
							end
						end
				else 
					@output_content = get_string("please enter a valid command","red")
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
		#get_line_default(highline)
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

	def clear
		system("clear")
	end
end


if __FILE__ == $0
	Main.new.play
end
