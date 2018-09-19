describe Main do
  subject { Main.new }
  before (:each) do
    subject.build_map(Constants::TestMap)
    subject.set_location(subject.map[0])
    subject.get_player('player')
    @player_bag = subject.player.bag
    @floor = subject.current_location.floor
  end
  describe '.initalize' do
    context "map shouldn't be empty on start" do
      it 'returns true' do
        expect(subject.map.empty?).to eq(false)
      end
    end
    context 'no room lacks a name' do
      it 'returns true' do
        subject.map.each do |room|
          expect(room.name.nil?).to eq(false)
        end
      end
    end
    context 'no room lacks a description' do
      it 'returns true' do
        subject.map.each do |room|
          expect(room.description.nil?).to eq(false)
        end
      end
    end
    context 'all rooms should have atleast one neighbor' do
      it 'returns true' do
        subject.map.each do |room|
          expect(room.neighbors[0][:name].nil? || room.neighbors[0][:direction].nil?).to eq(false)
        end
      end
    end
    context 'no neighbors lack a name' do
      it 'returns true' do
        subject.map.each do |room|
          room.neighbors.each do |neighbor|
            expect(neighbor[:name].nil?).to eq(false)
          end
        end
      end
    end
    context 'no neighbors lack a description' do
      it 'returns true' do
        subject.map.each do |room|
          room.neighbors.each do |neighbor|
            expect(neighbor[:direction].nil?).to eq(false)
          end
        end
      end
    end
    context 'no item lacks a name' do
      it 'returns true' do
        subject.map.each do |room|
          room.floor.contents.each do |item|
            expect(item.name.nil?).to be(false)
          end
        end
      end
    end
    context 'no item lacks a description' do
      it 'returns true' do
        subject.map.each do |room|
          room.floor.contents.each do |item|
            expect(item.desc.nil?).to be(false)
          end
        end
      end
    end
    context 'no item lacks a weight' do
      it 'returns true' do
        subject.map.each do |room|
          room.floor.contents.each do |item|
            expect(item.weight.nil?).to be(false)
          end
        end
      end
    end
  end
  describe '.move' do
    context 'given a direction with no exit' do
      let(:input) { 'south' }
      it 'move should return failure' do
        subject.move(input)
        # looking for red text (fail) with \e{31m
        expect(subject.output_content).to include("\e[31m")
      end
    end
    context 'given a direction with an exit' do
      let(:input) { 'north' }
      it 'move should return success' do
        subject.move(input)
        expect(subject.previous_location.last).not_to eq subject.current_location
      end
    end
    context 'when told to move back' do
      let(:input) { 'back' }
      it 'move should fail if there are no previous locations' do
        location = subject.current_location
        subject.move(input)
        expect(subject.current_location).to eql location
      end
    end
    context 'when moving in a direction with a locked door' do
      let(:input) { 'east' }
      it 'move should fail without the key' do
        subject.move(input)
        expect(subject.output_content).to include("\e[31m")
      end
    end
    context 'when told to move back' do
      let(:input) { 'back' }
      it 'move should should succeed if there are one or more previous locations' do
        subject.move('north')
        previous_location = subject.previous_location.last
        subject.move(input)
        expect(subject.current_location).to eq previous_location
      end
    end
    context 'given no direction' do
      let(:input) { nil }
      it 'move should fail' do
        subject.move(input)
        expect(subject.output_content).to include("\e[31m")
      end
    end
  end
  describe 'item interaction' do
    let(:item) { Item.new('test item', 1) }
    describe '.grab' do
      context 'given a valid item to pick up' do
        let(:input) { %w[test item] }
        it 'should add the item to the player inventory' do
          @floor.add_item(item)
          subject.grab(input, @floor)
          expect(@floor.contents.include?(item)).to be false
          expect(@player_bag.contents.include?(item)).to be true
        end
      end
      context 'given an invalid item to pick up' do
        let(:input) { %w[test item] }
        it 'should not add the item to the player inventory' do
          subject.grab(input, @floor)
          expect(@floor.contents.include?(item)).to be false
          expect(@player_bag.contents.include?(item)).to be false
        end
      end
      context 'given no input' do
        let(:input) { [] }
        it 'should request input from user' do
          allow($stdout).to receive(:write)
          expect(ARGF).to receive(:gets).and_return('')
          subject.grab(input, @floor)
        end
      end
    end
    describe '.drop' do
      context 'when requesting to drop an item with an empty inventory' do
        let(:input) { %w[test item] }
        it 'should alert the player there is nothing to drop' do
          subject.drop(input, @floor)
          expect(subject.output_content).to include("\e[31m")
        end
      end
      context "when requesting to drop an item that isn't in the inventory and inventory is not empty" do
        let(:input) { %w[test item] }
        it 'it should not drop the item' do
          subject.drop(input, @floor)
          expect(@floor.contents.include?(item)).to be false
          expect(@player_bag.contents.include?(item)).to be false
        end
      end
      context 'when requesting to drop an item that is in the inventory' do
        let(:input) { %w[test item] }
        it 'it should drop the item' do
          @player_bag.add_item(item)
          subject.drop(input, @floor)
          expect(@floor.contents.include?(item)).to be true
          expect(@player_bag.contents.include?(item)).to be false
        end
      end
    end
  end
  describe '.look' do
    context 'when look is input without any parameters' do
      let(:command) {nil}
      let(:params) {[]}
      it 'will ask for further input' do
        allow($stdout).to receive(:write)
        expect(ARGF).to receive(:gets).and_return('foo')
        subject.look(command,params)
      end
    end
    context 'when look is input with "at the room"' do
      let(:command) { 'at' }
      let(:params) { ['the', 'room'] }
      it 'will call look_room' do
        expect(subject).to receive(:look_room)
        subject.look(command,params)
      end
    end
    context 'when look is input with "at" and followed by an item' do
      let(:command) { 'at' }
      let(:params) { ['test', 'item'] }
      it 'will call look_at' do
        expect(subject).to receive(:look_at)
        subject.look(command,params)
      end
    end
  end
  describe '.look_at' do
    let(:item) { Item.new('test item', 1) }
    context 'when looking at an item that is not visible to the player' do
      let(:input) { ['test', 'item'] }
      it 'will inform the player it is not possible' do
        subject.look_at(input)
        expect(subject.output_content).to include("\e[31m")
      end
    end
    context 'when looking at an item the the player is holding' do
      let(:input) { ['test', 'item' ] }
      it "will find the item's description" do
        @player_bag.add_item(item)
        subject.look_at(input)
        expect(subject.output_content).to include("\e[32m")      
      end
    end
    context 'when looking at an item that is in the same room as the player' do
      let(:input) { ['test', 'item' ] }
      it "will find the item's description" do
        @floor.add_item(item)
        subject.look_at(input)
        expect(subject.output_content).to include("\e[32m")      
      end
    end
  end

  describe '.use' do
    let(:item) { CombinableItem.new('test object', 1, 'test block', 'it is a test object') }
    let(:item2) { CombinableItem.new('test block', 1, 'test object', 'it is a test block') }
    context 'when trying to use an item on another object which it cannot interactive with' do
      it 'will fail' do
        @player_bag.add_item(item)
        subject.use(['test', 'object', 'on', 'big', 'rock']) 
        expect(subject.output_content).to include("\e[31m")
      end
    end
    context 'when unlocking a door and then attempting to move through it' do
      let(:input) { 'east' }
      let(:params) { %w[round key on first door] }
      it 'move should return success' do
        subject.grab(%w[round key], @floor)
        subject.use(params)
        subject.move(input)
        expect(subject.previous_location.last).not_to eq subject.current_location
      end
    end
    context 'when attempting to use an item not held by the player' do
      it 'will fail' do
        subject.use(['test', 'item', 'on', 'big', 'rock']) 
        expect(subject.output_content).to include("\e[31m")
      end
    end
    context 'when using 2 held items on eachother that are compatible' do
      let(:input) {['test', 'object', 'on', 'test', 'block']}
      it 'will add to the players inventory if they have enough capacity' do
        @player_bag.add_item(item)
        @player_bag.add_item(item2)
        subject.use(input)
        expect(@player_bag.contents.include?(item)).to be false
        expect(@player_bag.contents.include?(item2)).to be false
        expect(@player_bag.contents.any? do |item| 
          true if item.name == 'test success'
        end).to be true 
      end
    end
    context 'when using a held item on a compatible item on the floor' do
      let(:input) {['test', 'object', 'on', 'test', 'block']}
      it 'will add to the players inventory if they have enough capacity' do
        @player_bag.add_item(item)
        @floor.add_item(item2)
        subject.use(input)
        expect(@player_bag.contents.include?(item)).to be false
        expect(@floor.contents.include?(item2)).to be false
        expect(@player_bag.contents.any? do |item| 
          true if item.name == 'test success'
        end).to be true
      end
    end
    context 'when combining an item that is too heavy for the player' do
      let(:item) { CombinableItem.new('heavy test item', 1, 'test block', 'it is a heavy test item') }
      let(:input) {['heavy','test', 'item', 'on', 'test', 'block']}
      it 'will add to the floor' do
        @player_bag.add_item(item)
        @floor.add_item(item2)
        subject.use(input)
        expect(@player_bag.contents.include?(item)).to be false
        expect(@floor.contents.include?(item2)).to be false
        expect(@floor.contents.any? do |item| 
          true if item.name == 'heavy test success'
        end).to be true
      end
    end
    context 'when using 2 held items that are both on the floor that are compatible' do
      let(:input){['test', 'object', 'on', 'test', 'block']}
      it 'will fail' do
        @floor.add_item(item)
        @floor.add_item(item2)
        subject.use(input)
        expect(subject.output_content).to include("\e[31m")
      end
    end
    context 'when trying to use a key and not providing an arguement to use with' do
      let(:item){Key.new('test key',1,'large door','it is a test key')}
      let(:input){['test', 'key']}
      it 'will ask for more input' do
        @player_bag.add_item(item)
        allow($stdout).to receive(:write)
        expect(ARGF).to receive(:gets).and_return('')
        subject.use(input)
      end
    end
    context 'when trying to use a combinable item and not providing an arguement to use with' do
      let(:input){['test', 'object']}
      it 'will ask for more input' do
        @player_bag.add_item(item)
        allow($stdout).to receive(:write)
        expect(ARGF).to receive(:gets).and_return('')
        subject.use(input)
      end
    end
    context 'when trying to use a switch and not providing an arguement to use with' do
      let(:item){DoorSwitch.new('test switch', 20, 'test room', 'south') }
      let(:input){['test', 'switch']}
      it 'will succeed' do
        @floor.add_item(item)
        subject.use(input)
        expect(subject.current_location.neighbors.any? do |neighbor|
          true if neighbor[:name] == 'test room'
        end).to be true
      end
    end
  end
end
