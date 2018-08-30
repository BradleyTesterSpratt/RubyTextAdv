describe Main do
  subject { Main.new }
  before (:each) do
    subject.build_map(Constants::TestMap)
    subject.set_location(subject.map[0])
    subject.get_player('player')
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
    context 'when moving in a direction with a unlocked door' do
      let(:input) { 'east' }
      let(:params) { %w[round key on first door] }
      it 'move should return success' do
        subject.grab(%w[round key], subject.current_location.floor)
        subject.use(params)
        subject.move(input)
        expect(subject.previous_location.last).not_to eq subject.current_location
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
    let(:player_bag) { subject.player.bag }
    let(:floor) { subject.current_location.floor }
    describe '.grab' do
      context 'given a valid item to pick up' do
        let(:input) { %w[test item] }
        it 'should add the item to the player inventory' do
          floor.add_item(item)
          subject.grab(input, floor)
          expect(floor.contents.include?(item)).to be false
          expect(player_bag.contents.include?(item)).to be true
        end
      end
      context 'given an invalid item to pick up' do
        let(:input) { %w[test item] }
        it 'should not add the item to the player inventory' do
          subject.grab(input, floor)
          expect(floor.contents.include?(item)).to be false
          expect(player_bag.contents.include?(item)).to be false
        end
      end
      context 'given no input' do
        let(:input) { [] }
        it 'should request input from user' do
          allow($stdout).to receive(:write)
          expect(ARGF).to receive(:gets).and_return('foo')
          subject.grab(input, subject.current_location.floor)
        end
      end
    end
    describe '.drop' do
      context 'when requesting to drop an item with an empty inventory' do
        let(:input) { %w[test item] }
        it 'should alert the player there is nothing to drop' do
          subject.drop(input, floor)
          expect(subject.output_content).to include("\e[31m")
        end
      end
      context "when requesting to drop an item that isn't in the inventory and inventory is not empty" do
        let(:input) { %w[test item] }
        it 'it should not drop the item' do
          subject.drop(input, floor)
          expect(floor.contents.include?(item)).to be false
          expect(player_bag.contents.include?(item)).to be false
        end
      end
      context 'when requesting to drop an item that is in the inventory' do
        let(:input) { %w[test item] }
        it 'it should drop the item' do
          player_bag.add_item(item)
          subject.drop(input, floor)
          expect(floor.contents.include?(item)).to be true
          expect(player_bag.contents.include?(item)).to be false
        end
      end
    end
  end
  describe '.look' do
  end

  describe '.use' do
  end
end
