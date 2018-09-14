describe Parser do
  describe '.call' do
    subject { Parser.new }
    describe 'command parsing' do
      context 'given a valid command string' do
        let(:input) { 'go north' }
        it 'returns the commands in an array with no params' do
          expect(subject.call(input)).to eq([['go','north'],[]])
        end
      end
      context 'given a repeated command' do
        let(:input) { 'go north go north' }
        it 'ignores repetition and returns commands in an array with no params' do
          expect(subject.call(input)).to eq([['go','north'],[]])
        end
      end
      context 'when no valid commands are given' do
        let(:input) { 'find sponge' }
        it 'returns nil' do
          expect(subject.call(input)).to be_nil
        end
      end
    end
    describe 'params parsing' do
      context 'when a command is given with a single parameter' do
        let(:input) { 'grab fork' }
        it 'returns an array with a single entry' do
          expect(subject.call(input)).to eq([['grab'],['fork']])
        end
      end
      context 'when given multiple parameters' do 
        let(:input) {'use fork on plug socket'}
        it 'returns an array with multiple entries' do
          expect(subject.call(input)).to eq([['use'],['fork', 'on', 'plug', 'socket']])
        end
      end
      context 'when given multiple parameters with repeated words' do
        let(:input) {'use big rock on small rock'}
        it 'returns an array with multiple entries including the repetition' do
          expect(subject.call(input)).to eq([['use'],['big', 'rock', 'on', 'small', 'rock']])
        end
      end
      context 'when given multiple repeated parameters and repated commands' do
        let(:input) {'use use big rock on small rock'}
        it 'returns an array with multiple entries including the repetition for parameters only' do
          expect(subject.call(input)).to eq([['use'],['big', 'rock', 'on', 'small', 'rock']])
        end
      end
    end
  end
end
