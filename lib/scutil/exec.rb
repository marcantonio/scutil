
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
      @username =  username.nil? ? ENV['USER'] : username
      @options = options
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
      sys_conn = nil
      conn = nil
      if Scutil.connection_cache.exists?(@hostname)
        sys_conn = Scutil.connection_cache.fetch(@hostname)
        conn = sys_conn.get_connection(@hostname, @username, pty_needed, @options)
      else
        sys_conn = SystemConnection.new(@hostname, @options)
        conn = sys_conn.get_connection(@hostname, @username, pty_needed, @options)
      end
      Scutil.connection_cache << sys_conn
      conn
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
      # Convenience method for uploading files.  Only available if you have
      # Net::SCP.  This function simply calls Net::SCP#upload! but reuses the
      # SSH connection if it's available.  All options and semantics are
      # identical to Scutil.exec_command and Net::SCP.
      #
      # <em>*NB:* This function currently calls the *blocking* +upload!+
      # function rather than the *non-blocking* _upload_ function.  This is by
      # design and will most likely be changed in the near future.</em>
      def upload(local, remote, options={}, &progress)
        set_options options
        conn.scp.upload!(local, remote, options={}, &progress)
      end
      
      # Convenience method for downloading files.  Only available if you have
      # Net::SCP.  This function simply calls Net::SCP#download! but reuses the
      # SSH connection if it's available.  All options and semantics are
      # identical to Scutil.exec_command and Net::SCP.
      #
      # <em>*NB:* This function currently calls the *blocking* +download!+
      # function rather than the *non-blocking* +download+ function.  This is by
      # design and will most likely be changed in the near future.</em>
      def download(remote, local=nil, options={}, &progress)
        set_options options
        conn.scp.download!(remote, local, options={}, &progress)
      end
    end
  end
end
