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
    @inv_content = ''
    @room_content = ''
    @output_content = ''
    @parser = Parser.new
    @previous_location= []
  end

  attr_reader :map, :output_content, :current_location, :player, :previous_location

  def play
    inital_setup
    play=true
    while play
      @inv_content= @inventory.contents.empty? ? get_string('Empty','green') : get_string(@inventory.display_contents.join(', ').to_s,"green")
      print_frames
      commands, params = @parser.call(get_input('Enter Command : ','yellow'))
      case
        when commands.nil? then @output_content = get_string("please enter a valid command","red")
        when commands[0] == "go" then move(commands[1])
        when commands[0] == "look" then look(commands[1],params)
        when commands[0] == "help" then help
        when commands[0] == "grab" then grab(params,@current_location.floor)
        when commands[0] == "drop" then drop(params,@current_location.floor)
        when commands[0] == "quit" then play = quit
        when commands[0] == "use" then use(params)
      end
    end
    clear
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

  def inital_setup
    build_map(Constants::TestMap)
    help
    print_frames
    set_location(map[0])
    print get_string("Enter your name : ","yellow")
    get_player(gets.chomp)
    print_frames
    look_room
  end

  def get_player(input)
    @player=Player.new(input)
    @inventory = @player.bag
  end

  def quit
    print get_string('type "yes" to quit: ',"yellow")
    false if (gets.chomp.downcase == "yes")
  end

  def help
    @room_content = get_string("Valid commands are:","green") + " \ngo north, go east, go west, go back\nlook, look around, grab\nquit, help"
  end

  def look(command,params)
    case
      when command == "around" then look_around
      when command == "at" then look_at(params)
      when command.nil? 
        print get_string("Look at what?: ","yellow")
        item=gets.chomp
    end
  end

  def look_at(params)
    params = params.join(' ')
    if params == 'the room' then look_room
    else
      item_list = @inventory.contents + @current_location.floor.contents
      @output_content = get_string("There is no #{params}", 'red')
      item_list.each do |item|
        @output_content = get_string("#{item.desc} and it weighs #{item.weight}", 'green') if item.name == params
      end
    end
  end

  def look_room
    @room_content = @current_location.description + "\n"
    @current_location.neighbors.each do |neighbor|  
      @room_content = @room_content + "There is an exit to the #{get_string(neighbor[:direction],"blue")}\n"
    end
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
    case
      when direction == "back" then
          if !@previous_location.empty?
            @current_location = @previous_location.pop
            @output_content = get_string("#{@player.name} returned to #{@current_location.name}","green")
            look_room
          else
            @output_content = get_string('#There are no previous locations for {@player.name} to return to','red')
            look_room
          end
      when direction.nil? then 
        @output_content = get_string("You need to give a direction","red")
      when !direction.nil? then
        can_move = false
        locked = false
        @current_location.neighbors.each do |neighbor|
          if neighbor[:direction].downcase == direction
            @map.each do |room|
              if room.name == neighbor[:name]
                if !neighbor[:door].nil?
                  @locked_door = neighbor[:door]
                  locked = true 
                else
                  set_location(room)
                  look_room
                  @output_content = get_string("#{@player.name} travelled #{direction}","green")
                  can_move=true
                end
              end
            end
          end
          if !can_move && !locked
            @output_content = get_string("There is nothing in that direction #{direction}","red") 
          elsif locked
            @output_content = get_string("#{direction} is blocked by #{@locked_door}","red") 
          end
        end
    end
  end

  def set_location(location)
    @previous_location << @current_location if !@current_location.nil?
    @current_location = location
  end

  def build_map(json)
    @map = []

    file = File.read(json)
    level_data = JSON.parse(file)

    level_data['Room'].each do |ent|
      room = Room.new(ent['name'], ent['desc'], ent['long_desc'])
      ent['neighbors'].each do |neighbor|
        room.add_neighbor(neighbor['name'], neighbor['direction'], neighbor['door'])
      end
      if !ent['items'].nil?
        ent['items'].each do |item|
          room.fill(Item.new(item['name'],item['weight'],item['type'],item['desc'],item['use_with']))
        end
      end
      @map << room
    end 
    @combined_items = build_combined_items(level_data, Constants::CombinedItems)
  end

  def build_combined_items(level_data,combined_items)
    items = JSON.parse(File.read(combined_items))
    items = items.merge(level_data){|k,o,v| o + v}
    items = items.select{|k, _| k == "items"}
  end

  def print_frames
    clear
    room_box = TTY::Box.frame(
      width: 50, 
      height: 10,  
      border: :thick) do
      @room_content
    end
    out_box = TTY::Box.frame(
      width: 50, 
      height: 4,  
      border: :thick, 
      style: { border: { fg: :yellow } } ) do
      @output_content
    end
    inv_box = TTY::Box.frame(
      width: 50, 
      height: 4,  
      border: :thick, 
      title: {top_left: "INVENTORY"}, 
      style: { border: { fg: :green } } ) do
      @inv_content
    end
    print room_box,out_box,inv_box
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

  def use (params)
    params = params.join(' ').chomp.split(' on ')
    if item = @current_location.floor.contents.find{ |item| item.name == params[0] && item.type == 'switch'}
      return switch_use(params, item) 
    end
    return @output_content = get_string("You are not holding a #{params[0]}", 'red') if not @inventory.contents.any? { |item| item.name == params[0] }
    item = @inventory.contents.find {|item| item.name == params[0] && item.use_with.include?(params[1]) }
    item.nil? ? @output_content = get_string("#{params[0]} cannot be used like that", 'red') : switch_use(params[1], item) 
  end



  #   if not @inventory.contents.any? { |item| item.name == params[0] }
  #     return @output_content = get_string("You are not holding a #{params[0]}", 'red') 
  #   end
  #   item = @inventory.contents.find {|item| item.name == params[0] && item.use_with.include?(params[1]) }
  #   item.nil? ? @output_content = get_string("#{params[0]} cannot be used like that", 'red') : switch_use(params[1], item) 

  # end

  def switch_use(params, item)
    case
      when item.type == 'key' then use_key(params)
      when item.type == 'combine' then use_combine(item, params)
      when item.type == 'switch' then use_door_switch(item)
    end
  end

  def use_key(door)
    @current_location.neighbors.each do |neighbor|
      if neighbor[:door] == door
        @output_content = get_string("#{neighbor[:door]} is unlocked", 'green')
        @current_location.unlock_neighbor(neighbor)
      end
    end
  end

  def use_combine(item, item_name)
    @inventory.contents.each do |other_item|
      combine_item(item,other_item) if item_name == other_item.name
    end
    @current_location.floor.contents.each do |other_item|
      combine_item(item, other_item, false) if item_name == other_item.name
    end
  end

  def combine_item(item_one, item_two, held=true)
    @inventory.remove_item(item_one)
    held ? @inventory.remove_item(item_two) : @current_location.floor.remove_item(item_two)
    item = @combined_items['items'].find {|item| item['req1']== item_one.name && item['req2'] == item_two.name  }
    if item['type'] == 'switch' 
      combined_item = DoorSwitch.new(item['name'],item['weight'],item['new_neighbor']['name'],item['new_neighbor']['direction'],item['desc']) 
    else 
      combined_item = Item.new(item['name'],item['weight'],item['type'],item['desc'],item['use_with']) 
    end
    @current_location.floor.add_item(combined_item) if not @inventory.add_item(combined_item) 
    @output_content = get_string("#{item_one.name} and #{item_two.name} has become #{combined_item.name}", "green")
  end

  def use_door_switch(item)
    @current_location.add_neighbor(item.neighbor_name,item.neighbor_direction)
  end

  def clear
    system("clear")
  end

end


if __FILE__ == $0
  Main.new.play
end

#when it creates a door switch in code, generates it all wrong