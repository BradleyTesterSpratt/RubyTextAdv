$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib')
require 'parser'
require 'room'
require 'constants'
require 'json'
require 'player'
require 'highline'

class Main
	def initialize
		@parser = Parser.new
		@map = []
		build_map(Constants::LevelOne)
	end

	attr_reader :map

	def play
		play=true
		clear
		print get_string("Enter your name : ","yellow")
		@player=Player.new(gets.chomp)
		@inventory = @player.bag
		@current_location=map[0]
		@previous_location= []
		look("help")
		while play
			valid_input=false
			while !valid_input
				#print get_string("Enter Command : ","yellow")
				input=get_input("Enter Command : ","yellow")#gets.chomp
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
							look
							puts get_string("You need to give a direction","red")
						else move(commands[1])
					end
				when commands[0] == "look" then
					case
						when commands[1]==nil then look
						when commands[1] == "around" then look_around
					else
						puts get_string("Look at what?","red")
					end
				when commands[0] == "quit"
					look
					print get_string('type "yes" to quit: ',"yellow")
					if (gets.chomp.downcase == "yes")
						play=false
						clear
					end
				when commands[0] == "help"
					look("help")
				when commands [0] == "grab"
					current_floor = @current_location.floor
					if current_floor.contents.empty?
						look
						puts get_string("There are no items","red")
					else
						print get_string("Enter object to grab: ","yellow")
						item=gets.chomp
						current_floor.contents.each do |valid_item| 
							if item == valid_item.name	
								if @inventory.add_item(valid_item)
									current_floor.remove_item(valid_item)
									look
									puts get_string("#{@player.name} picked up the #{item}","green")
								else
									look
									puts get_string("#{item} is too heavy","red")
								end
							else
								puts "debug"
							end
						end
					end
				when commands[0] == "drop"
					current_floor = @current_location.floor
					if @inventory.contents.empty?
						look
						puts get_string("#{@player.name} has nothing to drop","red")
						else
							print get_string("Enter object to drop: ","yellow")
							item=gets.chomp
							@inventory.contents.each do |valid_item| 
								if item == valid_item.name	
									if current_floor.add_item(valid_item)
										@inventory.remove_item(valid_item)
										look
										puts get_string("#{@player.name} dropped the #{item}","green")
									else
										look
										puts get_string("There is no room on the floor for #{item}","red")
									end
								end
							end
						end
				else 
					look
					puts get_string("please enter a valid command","red")
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
		print get_string("Inventory : ","green")
		@inventory.contents.empty? ? (puts get_string("[ Empty ]","green")) : (puts get_string(@inventory.display_contents.to_s,"green"))
		print get_string(string,colour)
		gets.chomp
	end

	def look(variable = nil)
		clear
		puts get_string("valid commands are :","green"), "go north, go east, go west, go back", "look, look around, grab", "quit, help", " " if !variable.nil?
		puts @current_location.description
		@current_location.neighbors.each do |neighbor|	
			#add exit description to json and use that
			puts "There is an exit to the #{get_string(neighbor[1],"blue")}."
		end
	end

	def look_around
		clear
		puts @current_location.long_description
		if !@current_location.floor.contents.empty?
			@current_location.floor.contents.each do |item|
				puts "There is a #{get_string(item.name,"green")}."
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
						@current_location = room
						look
						puts get_string("#{@player.name} travelled #{direction}","green")
						can_move=true
					end
				end
			end
		end
		if !can_move
			look
			puts get_string("There is nothing in that direction","red") 
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

	def clear
		system("clear")
	end
end


if __FILE__ == $0
	Main.new.play
end
