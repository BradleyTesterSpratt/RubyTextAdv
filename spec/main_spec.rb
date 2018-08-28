describe Main do
  subject {Main.new}
  before (:each) do
    subject.build_map(Constants::TestMap)
    subject.set_location(subject.map[0])
    subject.player=Player.new('player')
  end
  describe ".initalize" do
    context "map shouldn't be empty on start" do
      it "returns true" do
        expect(subject.map.empty?).to eq(false)
      end
    end
    context "no room lacks a name" do
      it "returns true" do
        subject.map.each do |room|
          expect(room.name.nil?).to eq(false)
        end
      end
    end
    context "no room lacks a description" do
      it "returns true" do
        subject.map.each do |room|
          expect(room.description.nil?).to eq(false)
        end
      end
    end
    context "all rooms should have atleast one neighbor" do
      it "returns true" do
        subject.map.each do |room|
          expect(room.neighbors[0][0].nil? || room.neighbors[0][1].nil?).to eq(false)
        end
      end
    end
    context "no neighbors lack a name" do
      it "returns true" do
        subject.map.each do |room|
          room.neighbors.each do |neighbor|
            expect(neighbor[0].nil?).to eq(false)
          end
        end
      end
    end
    context "no neighbors lack a description" do
      it "returns true" do
        subject.map.each do |room|
          room.neighbors.each do |neighbor|
            expect(neighbor[1].nil?).to eq(false)
          end
        end
      end
    end
  end
  describe ".move" do
    subject {Main.new}
    context "given a direction with no exit" do
      let(:input) {'south'}
      it "move should return failure" do
        subject.move(input)
        #looking for red text (fail) with \e{31m
        expect(subject.output_content).to include("\e[31m")
      end
    end
    context "given a direction with an exit" do
      let(:input) {'north'}
      it "move should return success" do
        subject.move(input)
        #looking for green text (success) with \e{31m
        expect(subject.output_content).to include("\e[32m")
      end
    end
    context "when told to move back" do
      let(:input) {'back'}
      it "move should fail if there are no previous locations" do
        subject.move(input)
        expect(subject.output_content).to include("\e[31m")
      end
    end
    context "when moving in a direction with a locked door" do
      let(:input) {'east'}
      it "move should fail without the key" do
        subject.move(input)
        expect(subject.output_content).to include("\e[31m")
      end
    end
    context "when told to move back" do
      let(:input) {'back'}
      it "move should should succed if there are one or more previous locations" do
        subject.move('north')
        subject.move(input)
        expect(subject.output_content).to include("\e[32m")
      end
    end
    context "given no direction" do
      let(:input) {nil}
      it "move should fail" do
        subject.move(input)
        expect(subject.output_content).to include("\e[31m")
      end
    end
  end
  describe ".look" do
    subject {Main.new}
  end
end