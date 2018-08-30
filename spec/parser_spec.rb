describe Parser do
  describe '.call' do
    subject { Parser.new }
    context 'given a valid command string' do
      let(:input) { 'go north' }
      it 'returns true' do
        expect(subject.call(input)).to eq(true)
      end
    end
    context 'given a repeated command' do
      let(:input) { 'go go north' }
      it 'ignores repetition and returns true' do
        expect(subject.call(input)).to eq(true)
      end
    end
  end
end
