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
        when commands[0] == "grab" then grab(params)
        when commands[0] == "drop" then drop(params)
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
    @room_content = get_string("Valid commands are:","green") + " \ngo north, go east, go west, go south, go back\nlook at item, look at the room, look around\ngrab, drop, use, use item on item\nquit, help"
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
          room.fill(build_items(item))
        end
      end
      @map << room
    end 
    @combined_items = build_combined_items(level_data, Constants::CombinedItems)
  end

  def build_items(item)
    case
      when item['type'] == 'key' then Key.new(item['name'],item['weight'],item['door'],item['desc'])
      when item['type'] == 'combine' then CombinableItem.new(item['name'],item['weight'],item['use_with'],item['desc'])
      when item['type'] == 'switch' then DoorSwitch.new(item['name'],item['weight'],item['new_neighbor']['name'],item['new_neighbor']['direction'],item['desc'])
      else Item.new(item['name'],item['weight'],item['desc'])
    end
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

  def move_item(params, origin, destination)
    interaction, action  = origin == @inventory ? ['drop','dropped'] : ['grab','picked up'] 
    if origin.contents.empty?
      @output_content = get_string("There are no items to #{interaction}","red")
    elsif params.empty?
      print get_string("Enter object to #{interaction}: ","yellow")
      item = gets.chomp
    else
      item = params.join(' ').chomp
    end
    if !item.nil?
    found = false         
      origin.contents.each do |valid_item| 
        if item == valid_item.name  
          found = true
          if destination.add_item(valid_item)
            origin.remove_item(valid_item)
            @output_content = get_string("#{@player.name} #{action} the #{item}","green")
          else 
            @output_content = get_string("#{item} is too heavy","red")
          end
        end
      end   
      @output_content = get_string("There is no #{item}","red") if !found
    end
  end

  def grab(params)
    move_item(params, @current_location.floor, @inventory) 
  end

  def drop (params)
    move_item(params,@inventory,@current_location.floor)
  end

  def use (params)
    params = params.join(' ').chomp.split(' on ')
    room_contents = @current_location.floor.contents + @inventory.contents 
    item = room_contents.find{ |item| item.name == params[0] }
    if (item.nil? || !item.type == 'switch')  
      @output_content = get_string("You are not holding a #{params[0]}", 'red') 
    else
      switch_use(item,params[1])
    end
  end

  def switch_use(item, other_item)
    case
      when item.type == 'key' then 
        if held?(item)
          use_key(item, other_item)
        else
          @output_content = get_string("You are not holding #{item.name}","red")
        end
      when item.type == 'combine' then 
        if held?(item)
          use_combine(item, other_item)
        else
          @output_content = get_string("You are not holding #{item.name}","red")
        end
      when item.type == 'switch' then use_door_switch(item)
      else @output_content = get_string("You cannot use #{item.name} like that","red")
    end
  end

  def use_key(key, door_name)
    while door_name.nil?
      door_name = get_input("use #{key.name} with which door?: ", 'yellow')
    end
    neighbor = @current_location.neighbors.find{ |neighbor| neighbor[:door] == door_name}
    if neighbor.nil? 
      @output_content = get_string("There isn't a #{door_name} to open", 'red')
    elsif key.door == door_name
      @output_content = get_string("#{neighbor[:door]} is unlocked", 'green')
      @current_location.unlock_neighbor(neighbor)
    else
      @output_content = get_string("#{door_name} isn't unlocked with #{key.name}", 'red')
    end
  end

  def use_combine(item, item_name)
    while item_name.nil?
      item_name = get_input("use #{item.name} with which what?: ", 'yellow')
    end
    (@inventory.contents + @current_location.floor.contents).each do |other_item|
      combine_item(item, other_item) if item_name == other_item.name
    end
  end

  def combine_item(item_one, item_two)
    item = @combined_items['items'].find {|item| item['requirements'].include?(item_one.name) && item['requirements'].include?(item_two.name) }
    if item.nil?
      @output_content = get_string("#{item_one.name} cannot be used with #{item_two.name}", "red")
    else
      @inventory.remove_item(item_one)
      held?(item_two) ? @inventory.remove_item(item_two) : @current_location.floor.remove_item(item_two) 
      combined_item = build_items(item)
      @current_location.floor.add_item(combined_item) if not @inventory.add_item(combined_item) 
      @output_content = get_string("#{item_one.name} and #{item_two.name} has become #{combined_item.name}", "green")
    end
  end

  def held?(item)
    @inventory.contents.include?(item)
  end

  def use_door_switch(item)
    if item.active
      @current_location.add_neighbor(item.neighbor_name,item.neighbor_direction)
      item.use_switch
      @output_content = get_string("The #{item.name} opened a hidden door opened to the #{item.neighbor_direction}", "green")
    else
      @output_content = get_string("The #{item.name} did nothing", "red")
    end
  end

  def clear
    system("clear")
  end

end


if __FILE__ == $0
  Main.new.play
end

#when it creates a door switch in code, generates it all wrong