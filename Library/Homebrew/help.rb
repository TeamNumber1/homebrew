module Homebrew extend self
  def help_for cmd, &block
    cmd = cmd.to_sym
    return cmd_help[cmd] if block.nil?
    help_string = block.call
    if help_string =~ /^\s+/
      indent = $&
      help_string = help_string.lines.map do |line|
        line.sub /^#{indent}/, ''
      end.join
    end
    cmd_help[cmd] = help_string
  end
  def print_help_for cmd
    puts help_for(cmd)
  end
end
