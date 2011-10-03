
module Scutil
  # Wrapper for each connection to a system.  Capabile of holding a
  # standard connect (@connection) and and PTY connection
  # (@pty_connection) for each system.
  class SystemConnection
    attr_reader :hostname,:pty_connection,:connection
    def initialize(hostname, options={})
      @hostname = hostname
      @connection = nil
      @pty_connection = nil
      @options = options
    end
    
    # Return a connection for system.  Checks to see if an established
    # connection exists.  If not it creates a new one.  Requests a PTY
    # if needed.
    def get_connection(hostname, username, pty_needed=false, options={})
      conn = nil
      # Local map has precedence.
      @options.merge!(options)
      
      scrub_options @options
      
      if (pty_needed)
        if !@pty_connection.nil?
          # Existing PTY connection
          print "[#{hostname}] Using existing connection (pty)\n" if @options[:scutil_verbose]
          return @pty_connection
        end
        
        # New PTY connection
        print "[#{hostname}] Opening new channel (pty) to system...\n" if @options[:scutil_verbose]
        conn = Net::SSH.start(hostname, username, @options)
        @pty_connection = conn
      else
        if !@connection.nil?
          # Existing non-PTY connection
          print "[#{hostname}] Using existing connection (non-pty)\n" if @options[:scutil_verbose]
          return @connection
        end
        
        # New non-PTY connection
        print "[#{hostname}] Opening channel (non-pty) to system...\n" if @options[:scutil_verbose]
        conn = Net::SSH.start(hostname, username, @options)
        @connection = conn
      end
      
      return conn
    end
    
    # Remove scutil specific options.  The rest go to Net::SSH.
    def scrub_options(options)
      options.delete(:scutil_verbose) if (options.has_key?(:scutil_verbose))
      options.delete(:scutil_force_pty) if (options.has_key?(:scutil_force_pty))
      options.delete(:scutil_pty_regex) if (options.has_key?(:scutil_pty_regex))
    end
    
    def to_s
      "#{self.class}: #{@hostname}, @connection = #{@connection}, @pty_connection = #{@pty_connection}"
    end
  end
end
