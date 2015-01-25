require 'spec_helper'

describe Rugments::Lexer do
  describe '::all' do
    it 'returns an array of all lexer classes' do
      lexers = Rugments::Lexer.all
      expect(lexers).to be_an_instance_of(Array)
      expect(lexers.first).to be_an_instance_of(Class)
      expect(lexers.size).to be > 1
    end
  end

  describe '::find_by_name' do
    it 'returns specifix lexer class' do
      lexer = Rugments::Lexer.find_by_name('C')
      expect(lexer.new).to be_an_instance_of(Rugments::Lexers::C)
    end
  end

  describe '::tag' do
    it 'returns the unique identifier' do
      lexer = Rugments::Lexer.find_by_name('ruby')
      expect(lexer.tag.to_s).to eq('ruby')
    end
  end

  describe '::title' do
    it 'returns the human readable title' do
      lexer = Rugments::Lexer.find_by_name('ruby')
      expect(lexer.title).to eq('Ruby')
    end
  end

  describe '::desc' do
    it 'returns the human readable description' do
      lexer = Rugments::Lexer.find_by_name('ruby')
      expect(lexer.desc).to eq('The Ruby programming language (ruby-lang.org)')
    end
  end

  describe '::aliases' do
    it 'returns the aliases array' do
      lexer = Rugments::Lexer.find_by_name('ruby')
      expect(lexer.aliases).to eq(%w(rb))
    end
  end

  describe '::filenames' do
    it 'returns the filenames array' do
      lexer = Rugments::Lexer.find_by_name('ruby')
      expect(lexer.filenames).to eq(
        %w(*.rb *.ruby *.rbw *.rake *.gemspec *.podspec Rakefile Guardfile
           Gemfile Capfile Podfile Vagrantfile *.ru *.prawn)
      )
    end
  end

  describe '::mimetypes' do
    it 'returns the mimetypes array' do
      lexer = Rugments::Lexer.find_by_name('ruby')
      expect(lexer.mimetypes).to eq(%w(text/x-ruby application/x-ruby))
    end
  end
end
