describe CommandWord do

  describe ".call" do
    subject {CommandWord.new}
    context "given a valid command" do
      let(:input) {"go"}
      it "returns true" do
        expect(subject.call(input)).to eq(true)
      end
    end
    context "given a valid command with upper and lower case" do
      let(:input) {"QuiT"}
      it "returns true" do
        expect(subject.call(input)).to eq(true)
      end
    end
    context "given and inavalid command" do
      let(:input) {"jump"}
      it "returns false" do
        expect(subject.call(input)).to eq(false)
      end
    end
  end
end