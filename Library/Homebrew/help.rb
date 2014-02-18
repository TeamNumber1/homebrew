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
    puts help_for(cmd)
  end
end
