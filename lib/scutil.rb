
=begin
The MIT License (MIT)

Copyright (C) 2011 by Marc Soda

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
=end

require 'net/ssh'

module Scutil
  # Utiliy class to hold all the connections created, possibly for
  # reuse later.
  class ConnectionCache
    attr_reader :cache
    include Enumerable

    def initialize
      @cache = []
    end

    # Need each to mixin Enumerable
    def each
      @cache.each do |c|
        yield c
      end
    end
    
    def fetch(hostname)
      each do |c|
        return c if c.hostname == hostname
      end
    end
    
    def exists?(hostname)
      each do |c|
        return true if c.hostname == hostname
      end
      false
    end

    # Remove all instances of _hostname_.
    def remove(hostname)
      @cache.delete_if { |c| c.hostname == hostname }
    end
    
    def <<(conn)
      @cache << conn
    end
    
    def to_s
      @cache.join("\n")
    end
  end
  
  SCUTIL_VERSION = '0.2.2'
  # By default, buffer 10M of data before writing.
  DEFAULT_OUTPUT_BUFFER_SIZE = 0xA00000
  # Checks for a command starting with _sudo_ by default.
  DEFAULT_PTY_REGEX = /^\s*sudo/
  @connection_cache = ConnectionCache.new
  @output_buffer_size = DEFAULT_OUTPUT_BUFFER_SIZE

  class << self
    # All successfully established connections end up here for reuse
    # later.
    attr_accessor :connection_cache
    # Set to 10M by default, this can be adjusted to tell scutil when
    # to write command output to _output_.
    attr_accessor :output_buffer_size
  end
  
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
          $stderr.print "[#{hostname}] Using existing connection (pty)\n" if @options[:scutil_verbose]
          return @pty_connection
        end
        
        # New PTY connection
        $stderr.print "[#{hostname}] Opening new channel (pty) to system...\n" if @options[:scutil_verbose]
        conn = Net::SSH.start(hostname, username, @options)
        @pty_connection = conn
      else
        if !@connection.nil?
          # Existing non-PTY connection
          $stderr.print "[#{hostname}] Using existing connection (non-pty)\n" if @options[:scutil_verbose]
          return @connection
        end
        
        # New non-PTY connection
        $stderr.print "[#{hostname}] Opening channel (non-pty) to system...\n" if @options[:scutil_verbose]
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
      "#{self.class}: #{@name}, @connection = #{@connection}, @pty_connection = #{@pty_connection}"
    end
  end
  
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
  
  class << self

    # Should we request a PTY?  Uses custom regex if defined in
    # +:scutil_pty_regex+.
    #
    def check_pty_needed?(cmd, options, hostname)
      regex = DEFAULT_PTY_REGEX
      if (options[:scutil_force_pty].nil?)
        # If a custom regex has been defined, use it.
        if (!options[:scutil_pty_regex].nil?)
          if options[:scutil_pty_regex].kind_of? Regexp
            regex = options[:scutil_pty_regex]
          else
            raise Scutil::Error.new("Error: :scutil_pty_regex must be a kind of Regexp", hostname)
          end
        else
          return (cmd =~ regex) ? true : false
        end
      else
        return options[:scutil_force_pty] ? true : false
      end
    end

    # Drops all instances of +hostname+ from connection_cache.
    def clear!(hostname)
      if (Scutil.connection_cache.exists?(hostname))
        Scutil.connection_cache.clear(hostname)
      else
        raise Scutil::Error.new("Error: :scutil_pty_regex must be a kind of Regexp", hostname)
      end
    end

    # Scutil.exec_command is used to execute a command, specified in
    # _cmd_, on a remote system.  The return value and any ouput of
    # the command are captured.
    #
    # If _output_ is a string it will be treated as a filename to be
    # opened (mode 'w+') and all command output will be written to
    # this file.  If _output_ is an IO object it will be treated as an
    # open file handle.*  Finally, if _output_ is omitted, or an empty
    # string, all command output will be directed to _$stdout_.
    #
    # <em>**NB:* This isn't actually true.  The only check made is to
    # see if _output_ responds to +:write+.  The idea being that not
    # only will a file handle have a +write+ method, but also
    # something like +StringIO+.  Using +StringIO+ here makes it easy
    # to capture the command's output in a string.  Suggestions on a
    # better way to do this are definitely welcome.</em>
    #
    # Scutil will automatically request a PTY if _sudo_ is at the
    # start of _cmd_.  Right now the regex that drives this isn't
    # configurable.  In a near future release it will be.  You can
    # force a PTY request by specifying +:scutil_force_pty+ in
    # _options_.
    #
    # Scutil.exec_command takes the following options:
    #
    # * :scutil_verbose   => Extra output.
    # * :scutil_force_pty => Force a PTY request (or not) for every channel.
    # * :scutil_pty_regex => Specific a custom regex here for use when
    #                        scutil decides whether or not to request a PTY.
    #
    # In addition, any other options passed Scutil.exec_command will
    # be passed on to Net::SSH, _except_ those prefixed with
    # _scutil__.
    #
    # All calls to Scutil.exec_command, regardless of the way it's
    # used, will return the remote command's return value.
    #
    #   retval = Scutil.exec_command('hostname', 'username', '/bin/true')
    #   puts "True is false!" if retval != 0
    #
    def exec_command(hostname, username, cmd, output=nil, options={})      
      # Do we need a PTY?
      pty_needed = check_pty_needed? cmd, options, hostname
      
      # Check for an existing connection in the cache based on the hostname.  If the 
      # hostname exists find a suitable connection.
      conn = nil
      begin
        if (Scutil.connection_cache.exists?(hostname))
          sys_conn = Scutil.connection_cache.fetch(hostname)
          conn = sys_conn.get_connection(hostname, username, pty_needed, options)
        else
          sys_conn = SystemConnection.new(hostname)
          $stderr.print "[#{hostname}] Adding new connection to cache\n" if options[:scutil_verbose]
          # Call get_connection first.  Don't add to cache unless established.
          conn = sys_conn.get_connection(hostname, username, pty_needed, options)
          Scutil.connection_cache << sys_conn
        end
      rescue Net::SSH::AuthenticationFailed => err
        raise Scutil::Error.new("Error: Authenication failed for user: #{username}", hostname)
      end
      
      fh = $stdout
      if (output.nil?)
        fh = $stdout
      elsif (output.respond_to? :write)
        # XXX: This may not be a safe assumuption...
        fh = output
      elsif (output.class == String)
        fh = File.open(output, 'w+') unless output.empty?
      else
        raise Scutil::Error.new("Error: Invalid output object type: #{output.class}.", hostname)
      end
      
      # Setup channel callbacks
      odata = ""
      edata = ""
      exit_status = 0
      chan = conn.open_channel do |channel|
        $stderr.print "[#{conn.host}:#{channel.local_id}] Setting up callbacks...\n" if options[:scutil_verbose]
        if (pty_needed)
          $stderr.print "[#{conn.host}:#{channel.local_id}] Requesting PTY...\n" if options[:scutil_verbose]
          # OPOST is necessary, CS8 makes sense.  Revisit after broader testing.
          channel.request_pty(:modes => { Net::SSH::Connection::Term::CS8 => 1, Net::SSH::Connection::Term::OPOST => 0 } ) do |ch, success|
            raise Scutil::Error.new("Failed to get a PTY", hostname) if !success
          end
        end
        
        channel.on_data do |ch, data|
#          $stderr.print "on_data: #{data.size}\n" if options[:scutil_verbose]
          odata += data

          # Only buffer some of the output before writing to disk (10M by default).
          if (odata.size >= Scutil.output_buffer_size)
            fh.write odata
            odata = ""
          end
        end
        
        channel.on_extended_data do |ch, type, data|
#          $stderr.print "on_extended_data: #{data.size}\n" if options[:scutil_verbose]
          edata += data
        end
        
        channel.on_close do |ch|
          $stderr.print "[#{conn.host}:#{channel.local_id}] on_close\n" if options[:scutil_verbose]
        end
        
        channel.on_open_failed do |ch, code, desc|
          raise Scutil::Error.new("Failed to open channel: #{desc}", hostname, code) if !success
        end

        channel.on_request("exit-status") do |ch, data|
          exit_status = data.read_long
        end

        channel.exec(cmd)
#        channel.wait
      end
      
      conn.loop

      # Write whatever is left
      fh.write odata

      # If extended_data was recieved there was a problem...
      raise Scutil::Error.new("Error: #{edata}", hostname, exit_status) unless (edata.empty?)

      # The return value of the remote command.
      return exit_status
    end
  end
  
  #  def xfer_file(hostname, username, src, dst, direction=:to, command=nil, options={})
  
  #  end
end

# Exception class for scutil.  The system, error message, and return
# value of the remote command are stored here on error.
#
#   begin
#     Scutil.exec_command('ls -al /root')
#   rescue Scutil::Error => err
#     puts "Message: " + err.message
#     puts "Hostname: " + err.hostname
#     puts "Exit status: #{err.command_exit_status}"
#   end
#
# Will produce:
#
#   Message: Error: ls: /root: Permission denied
#   Hostname: server.name.com
#   Exit status: 2
#
class Scutil::Error < StandardError
  attr_reader :hostname,:message,:command_exit_status
  
  def initialize(message=nil, hostname=nil, command_exit_status=-1)
    @message = message
    @hostname = hostname
    @command_exit_status = command_exit_status
  end

  def to_s
    "Message: #{@message}\nHostname: #{@hostname}\nExit status: #{command_exit_status}\n"
  end
end
