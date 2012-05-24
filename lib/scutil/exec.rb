
module Scutil  
  # Instantiate this class if you wish to use scutil as an object.
  # For example:
  #
  #   exec = Scutil::Exec.new('severname', 'mas')
  #
  #   exec.exec_command('echo "foo"')
  #
  #   exec.exec_command('echo "bar"; sudo whoami', nil, 
  #                     { :scutil_force_pty => true, 
  #                       :scutil_verbose => true 
  #                     })
  #
  class Exec
    include Scutil
    attr_reader :hostname,:username
    
    # Defaults to current user (ENV['USER']) if _username_ is not
    # specified.
    def initialize(hostname, username=nil, options={})
      @hostname = hostname
      @username = username.nil? ? ENV['USER'] : username
      @options  = options
    end
    
    # See Scutil.exec_command.  Takes _cmd_ and optionally _output_, and
    # _options_.  Other arguments specified at class initialization.
    #
    # The _options_ specified here will take precedence over those specified in
    # the constructor.
    def exec_command(cmd, output=nil, options={})
      # Local map has precedence.
      set_options(options)
      Scutil.exec_command(@hostname, @username, cmd, output, @options)
    end
    
    # Exposes the raw Net::SSH::Connection::Session object associated
    # with +:hostname+.
    def conn(pty_needed=false)
      Scutil.find_connection(@hostname, @username, pty_needed=false, @options)
    end
    
    # Alter the options set on this instance.
    def set_options(options={})
      @options.merge!(options)
    end
    
    begin
      require 'net/scp'
    rescue LoadError
    end
    
    if defined? Net::SCP
      # See Scutil.upload.  The _options_ specified here will take precedence
      # over those specified in the constructor.
      def upload(local, remote, options={}, &progress)
        set_options options
        Scutil.upload(@hostname, @username, local, remote, @options, &progress)
      end
      
      # See Scutil.download.  The _options_ specified here will take precedence
      # over those specified in the constructor.
      def download(remote, local=nil, options={}, &progress)
        set_options options
        Scutil.download(@hostname, @username, remote, local, @options, &progress)
      end
    end
  end
end
