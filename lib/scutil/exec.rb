
module Scutil  
  # Instantiate this class if you wish to use scutil as an object.
  # For example:
  #
  #   exec = Scutil::Exec.new('severname', 'mas')
  #
  #   exec.exec_command('echo "foo"')
  #
  #   exec.exec_command('echo "bar"; sudo whoami', "", 
  #                     { :scutil_force_pty => true, 
  #                       :scutil_verbose => true 
  #                     })
  #
  class Exec
    include Scutil
    attr_reader :hostname,:username
    
    def initialize(hostname, username, options={})
      @hostname = hostname
      @username = username
      @options = options
    end
    
    # See Scutil.exec_command.  Takes _cmd_ and optionally _output_,
    # and _options_.  Other arguments specified at class
    # initialization.
    #
    # The _options_ specified here will take precedence over those
    # specified in the constructor.
    def exec_command(cmd, output=nil, options={})
      # Local map has precedence.
      @options.merge!(options)
      Scutil.exec_command(@hostname, @username, cmd, output, @options)
    end
  end
end
