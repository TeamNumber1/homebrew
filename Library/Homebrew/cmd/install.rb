require 'formula_installer'
require 'hardware'
require 'blacklist'
require 'help'

module Homebrew extend self
  help_for :install do
    <<-eos
    `install [--debug] [--env=<std|super>] [--ignore-dependencies] [--only-dependencies] [--fresh] [--cc=<compiler>] [--build-from-source] [--devel|--HEAD]` <formula>:
        Install <formula>.

        <formula> is usually the name of the formula to install, but it can be specified
        several different ways. See [SPECIFYING FORMULAE][].

        If `--debug` is passed and brewing fails, open an interactive debugging
        session with access to IRB, ruby-debug, or a shell inside the temporary
        build directory.

        If `--env=std` is passed, use the standard build environment instead of superenv.

        If `--env=super` is passed, use superenv even if the formula specifies the
        standard build environment.

        If `--ignore-dependencies` is passed, skip installing any dependencies of
        any kind. If they are not already present, the formula will probably fail
        to install.

        If `--only-dependencies` is passed, install the dependencies with specified
        options but do not install the specified formula.

        If `--fresh` is passed, the installation process will not re-use any
        options from previous installs.

        If `--cc=<compiler>` is passed, attempt to compile using <compiler>.
        <compiler> should be the name of the compiler's executable, for instance
        `gcc-4.2` for Apple's GCC 4.2, or `gcc-4.8` for a Homebrew-provided GCC
        4.8.

        If `--build-from-source` is passed, compile from source even if a bottle
        is provided for <formula>.

        If `--devel` is passed, and <formula> defines it, install the development version.

        If `--HEAD` is passed, and <formula> defines it, install the HEAD version,
        aka master, trunk, unstable.

        To install a newer version of HEAD use
        `brew rm <foo> && brew install --HEAD <foo>`.
eos
  end
  def install
    return print_help_for(:install) if ARGV.include?('-h') || ARGV.include?('--help')
    raise FormulaUnspecifiedError if ARGV.named.empty?

    {
      'gcc' => 'gcc-4.2',
      'llvm' => 'llvm-gcc',
      'clang' => 'clang'
    }.each_pair do |old, new|
      opt = "--use-#{old}"
      if ARGV.include? opt then opoo <<-EOS.undent
        #{opt.inspect} is deprecated and will be removed in a future version.
        Please use "--cc=#{new}" instead.
        EOS
      end
    end

    if ARGV.include? '--head'
      raise "Specify `--HEAD` in uppercase to build from trunk."
    end

    ARGV.named.each do |name|
      # if a formula has been tapped ignore the blacklisting
      if not File.file? HOMEBREW_REPOSITORY/"Library/Formula/#{name}.rb"
        msg = blacklisted? name
        raise "No available formula for #{name}\n#{msg}" if msg
      end
      if not File.exist? name and name =~ HOMEBREW_TAP_FORMULA_REGEX then
        require 'cmd/tap'
        install_tap $1, $2
      end
    end unless ARGV.force?

    perform_preinstall_checks
    begin
      ARGV.formulae.each do |f|
        begin
          install_formula(f)
        rescue CannotInstallFormulaError => e
          ofail e.message
        end
      end
    rescue FormulaUnavailableError => e
      ofail e.message
      require 'cmd/search'
      puts 'Searching taps...'
      puts_columns(search_taps(query_regexp(e.name)))
    end
  end

  def check_ppc
    case Hardware::CPU.type when :ppc, :dunno
      abort <<-EOS.undent
        Sorry, Homebrew does not support your computer's CPU architecture.
        For PPC support, see: https://github.com/mistydemeo/tigerbrew
        EOS
    end
  end

  def check_writable_install_location
    raise "Cannot write to #{HOMEBREW_CELLAR}" if HOMEBREW_CELLAR.exist? and not HOMEBREW_CELLAR.writable_real?
    raise "Cannot write to #{HOMEBREW_PREFIX}" unless HOMEBREW_PREFIX.writable_real? or HOMEBREW_PREFIX.to_s == '/usr/local'
  end

  def check_xcode
    require 'cmd/doctor'
    checks = Checks.new
    doctor_methods = ['check_xcode_clt', 'check_xcode_license_approved',
                      'check_for_osx_gcc_installer']
    doctor_methods.each do |check|
      out = checks.send(check)
      opoo out unless out.nil?
    end
  end

  def check_macports
    unless MacOS.macports_or_fink.empty?
      opoo "It appears you have MacPorts or Fink installed."
      puts "Software installed with other package managers causes known problems for"
      puts "Homebrew. If a formula fails to build, uninstall MacPorts/Fink and try again."
    end
  end

  def check_cellar
    FileUtils.mkdir_p HOMEBREW_CELLAR if not File.exist? HOMEBREW_CELLAR
  rescue
    raise <<-EOS.undent
      Could not create #{HOMEBREW_CELLAR}
      Check you have permission to write to #{HOMEBREW_CELLAR.parent}
    EOS
  end

  def perform_preinstall_checks
    check_ppc
    check_writable_install_location
    check_xcode
    check_macports
    check_cellar
  end

  def install_formula f
    fi = FormulaInstaller.new(f)
    fi.install
    fi.caveats
    fi.finish
  rescue FormulaInstallationAlreadyAttemptedError
    # We already attempted to install f as part of the dependency tree of
    # another formula. In that case, don't generate an error, just move on.
  rescue FormulaAlreadyInstalledError => e
    opoo e.message
  # Ignore CannotInstallFormulaError and let caller handle it.
  end
end
