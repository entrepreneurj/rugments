require 'pp'

namespace :mappings do
  desc 'Create lexer mappings'
  task :lexers do
    mappings = {}
    lib_path = File.expand_path(File.join(File.dirname(__FILE__), '../lib'))

    # We have to load all lexers manually because we want to update
    # LEXERS_CACHE. So we cannot rely on LEXERS_CACHE to find lexers.
    require_relative File.join(lib_path, 'rugments.rb')
    lexer_paths = Dir.glob(File.join(lib_path, 'rugments/lexers/*.rb'))
    lexer_paths.select { |path| File.basename(path) != 'mappings.rb' }
    lexer_paths.each { |path| require_relative path }

    lexer_syms = Rugments::Lexers.constants.select do |c|
      Rugments::Lexers.const_get(c).is_a?(Class)
    end
    lexer_classes = lexer_syms.map { |sym| Rugments::Lexers.const_get(sym) }

    lexer_classes.each do |klass|
      unless klass.tag.nil?
        mappings[klass.tag.to_sym] = {}
        mappings[klass.tag.to_sym][:class_name] = klass.name
        mappings[klass.tag.to_sym][:source_file] = File.join('lexers', klass.tag.to_s + '.rb')
        mappings[klass.tag.to_sym][:aliases] = klass.aliases
        mappings[klass.tag.to_sym][:filenames] = klass.filenames
        mappings[klass.tag.to_sym][:mimetypes] = klass.mimetypes
      end
    end

    File.open(File.join(lib_path, 'rugments/lexers/mappings.rb'), 'w') do |f|
      f.puts '# Autogenerated by "rake mappings:lexers". Everytime you edit a'
      f.puts '# builtin lexer definition run "rake mappings:lexers" to update'
      f.puts '# the cache.'
      f.puts '#'
      f.puts '# Do not alter LEXERS_CACHE manually!'
      f.puts ''
      f.puts 'module Rugments'
      f.print '  LEXERS_CACHE = '
      PP.pp mappings, f
      f.puts 'end'
    end
  end

  desc 'Create all mappings'
  task :all do
    Rake::Task['mappings:lexers'].invoke
  end
end