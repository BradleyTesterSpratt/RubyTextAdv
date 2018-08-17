describe Main do
	describe ".initalize" do
    subject {Main.new}
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
end