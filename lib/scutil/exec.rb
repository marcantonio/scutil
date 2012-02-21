
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
    
    # Defaults to current user (ENV['USER'] if _username_ is not
    # specified.
    def initialize(hostname, username=nil, options={})
      @hostname = hostname
      @username =  username.nil? ? ENV['USER'] : username
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
      set_options(options)
      Scutil.exec_command(@hostname, @username, cmd, output, @options)
    end
    
    def set_options(options={})
      @options.merge!(options)      
    end
    
    # Exposes the raw Net:SSH::Connection::Session object associated
    # with @hostname.
    def conn(pty_needed=false)
      conn = nil
      if Scutil.connection_cache.exists?(@hostname)
        sys_conn = Scutil.connection_cache.fetch(@hostname)
        conn = sys_conn.get_connection(@hostname, @username, pty_needed, @options)
      else
        sys_conn = SystemConnection.new(@hostname, @options)
        conn = sys_conn.get_connection(@hostname, @username, pty_needed, @options)
      end
      conn
    end
  end
end
