require 'spec_helper'

describe Rugments::Lexer do
  describe '::all' do
    it 'returns an array of all lexer classes' do
      lexers = Rugments::Lexer.all
      expect(lexers).to be_an_instance_of(Array)
      expect(lexers[0]).to be_an_instance_of(Class)
      expect(lexers.size).to be > 1
    end
  end

  describe '::find_by_name' do
    it 'returns specifix lexer class' do
      lexer = Rugments::Lexer.find_by_name('C')
      expect(lexer.new).to be_an_instance_of(Rugments::Lexers::C)
    end
  end
end
