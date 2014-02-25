require 'extend/converter'

module Homebrew extend self
  def help_for cmd, &block
    cmd = cmd.to_sym
    if block.nil?
      # Get the generator proc and call it to get a help string
      gen = cmd_help[cmd]
      help_string = gen.call
      if help_string =~ /^\s+/
        indent = $&
        help_string = help_string.lines.map do |line|
          line.sub /^#{indent}/, ''
        end.join
      end
    else
      cmd_help[cmd] = block
    end
  end
  def print_help_for cmd
    begin
      unless defined? Kramdown
        require 'rubygems'
        require 'kramdown'
      end
    rescue LoadError => e
      odie "Missing kramdown gem. Please run:\n  `sudo /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/bin/gem install kramdown`"
    end
    data = help_for(cmd)
    doc  = Kramdown::Document.new(data)
    puts Converter.convert(doc)
  end
end
