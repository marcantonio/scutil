
=begin
The MIT License (MIT)

Copyright (C) 2012 by Marc Soda

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
=end

require 'net/ssh'
require 'scutil/exec'
require 'scutil/error'
require 'scutil/connection_cache'
require 'scutil/system_connection'

module Scutil
  SCUTIL_VERSION = '0.4.5'
  
  # By default, buffer 10M of data before writing.
  DEFAULT_OUTPUT_BUFFER_SIZE = 0xA00000
  
  # Checks for a command starting with _sudo_ by default.
  DEFAULT_PTY_REGEX = /^\s*sudo/
  
  # Default password prompt is <em>[sudo] password for</em>.  Redhat based systems use
  # _Password:_ instead.
  DEFAULT_SUDO_PASSWD_REGEX = /^\[sudo\] password for/
  # DEFAULT_PASSWD_REGEX = /^Password:/
  
  # Default password failed prompt is <em>Sorry, try again</em>.
  DEFAULT_SUDO_PASSWD_FAILED_REGEX = /^Sorry, try again/
  
  @connection_cache = ConnectionCache.new
  @output_buffer_size = DEFAULT_OUTPUT_BUFFER_SIZE
  
  class << self
    # All successfully established connections end up here for reuse later.
    attr_accessor :connection_cache
    # Set to 10M by default, this can be adjusted to tell scutil when to write
    # command output to _output_.
    attr_accessor :output_buffer_size
    
    # Should we request a PTY?  Uses custom regex if defined in
    # +:scutil_pty_regex+.
    def check_pty_needed?(cmd, options, hostname)      
      if options[:scutil_force_pty]
        return true
      end
      
      if !options[:scutil_pty_regex].kind_of? Regexp
        raise Scutil::Error.new(":scutil_pty_regex must be a kind of Regexp", hostname)
      end
      return (cmd =~ options[:scutil_pty_regex]) ? true : false
    end
    
    # Drops all instances of +hostname+ from @connection_cache.
    def clear!(hostname)
      if (Scutil.connection_cache.exists?(hostname))
        Scutil.connection_cache.remove(hostname)
      end
    end
    
    # Scutil.exec_command is used to execute a command, specified in _cmd_, on a
    # remote system.  The return value and any ouput of the command are
    # captured.
    #
    # If _output_ is a string it will be treated as a filename to be opened
    # (mode 'w') and all command output will be written to this file.  If
    # _output_ is an IO object it will be treated as an open file handle.
    # Finally, if _output_ is omitted, or an empty string, all command output
    # will be directed to <em>$stdout</em>.
    #
    # <em>*NB:* This isn't actually true.  The only check made is to see if
    # _output_ responds to +:write+.  The idea being that not only will a file
    # handle have a +write+ method, but also something like +StringIO+.  Using
    # +StringIO+ here makes it easy to capture the command's output in a string.
    # Suggestions on a better way to do this are definitely welcome.</em>
    #
    # Scutil will automatically request a PTY if _sudo_ is at the start of
    # _cmd_.  This is driven by a regex which is customizable via the option
    # +:scutil_pty_regex+.  You can also force a PTY request by specifying
    # +:scutil_force_pty+ in _options_.
    #
    # Scutil.exec_command takes the following options:
    #
    # * :scutil_verbose                  => Extra output.
    # * :scutil_force_pty                => Force a PTY request (or not) for every channel.
    # * :scutil_pty_regex                => Specific a custom regex here for use when scutil decides whether or not to request a PTY.
    # * :scutil_sudo_passwd_regex        => If sudo requires a password you can specify the prompt to look for, e.g., _Password:_ .
    # * :scutil_sudo_passwd_failed_regex => Regular expression for a sudo password failure.
    # * :scutil_sudo_passwd              => The sudo password.
    #
    # In addition, any other options passed Scutil.exec_command will be passed
    # on to Net::SSH, _except_ those prefixed with _scutil__.
    #
    # All calls to Scutil.exec_command, regardless of the way it's used, will
    # return the remote command's return value:
    #
    #   retval = Scutil.exec_command('hostname', 'username', '/bin/true')
    #   puts "True is false!" if retval != 0
    #
    # See the _test_ directory for more usage examples.
    def exec_command(hostname, username, cmd, output=nil, new_options={})
      # Fill in defaults
      options = get_default_options
      options.merge! new_options
      
      # Do we need a PTY?
      pty_needed = check_pty_needed? cmd, options, hostname
      
      conn = find_connection(hostname, username, pty_needed, options)
      
      fh = $stdout
      if (output.nil?)
        fh = $stdout
      elsif (output.respond_to? :write)  # XXX: This may not be a safe assumuption...
        fh = output
      elsif (output.class == String)
        fh = File.open(output, 'w') unless output.empty?
      else
        raise Scutil::Error.new("Invalid output object type: #{output.class}.", hostname)
      end
      
      # If a custom password prompt regex has been defined, use it.
      passwd_regex = set_sudo_password_prompt(options)
      
      # If a custom bad password prompt regex has been defined, use it.
      passwd_failed_regex = set_sudo_password_failed(options)
      
      # Setup channel callbacks
      odata = ""
      edata = ""
      exit_status = 0
      # Catch the first call to on_data
      sudo_passwd_state = :new
      chan = conn.open_channel do |channel|
        print "[#{conn.host}:#{channel.local_id}] Setting up callbacks...\n" if options[:scutil_verbose]
        if (pty_needed)
          print "[#{conn.host}:#{channel.local_id}] Requesting PTY...\n" if options[:scutil_verbose]
          # OPOST is necessary, CS8 makes sense.  Revisit after broader testing.
          channel.request_pty(:modes => { Net::SSH::Connection::Term::CS8 => 1, 
                                Net::SSH::Connection::Term::OPOST => 0 } ) do |ch, success|
            raise Scutil::Error.new("Failed to get a PTY", hostname) if !success
          end
        end
        
        channel.on_data do |ch, data|
#          print "on_data: #{data.size}\n" if options[:scutil_verbose]
          
          # sudo password states are as follows:
          #  :new     => Connection established, first data packet.
          #  :waiting => Password sent, wating for reply.
          #  :done    => Authenication complete or not required.
          case (sudo_passwd_state)
          when :done
            odata += data
          when :new
            if (data =~ passwd_regex) # We have been prompted for a sudo password
              if (options[:scutil_sudo_passwd].nil?) # No password defined, bail
                raise Scutil::Error.new("[#{conn.host}:#{channel.local_id}] Password required for sudo.  
Define in :scutil_sudo_passwd.", hostname)
                channel.close
              end
              ch.send_data options[:scutil_sudo_passwd] + "\n"
              sudo_passwd_state = :waiting
            else # No sudo password needed, grab the data and move on.
              odata += data
              sudo_passwd_state = :done
            end
          when :waiting
            if (data =~ passwd_failed_regex) # Bad sudo password
              raise Scutil::Error.new("[#{conn.host}:#{channel.local_id}] Password failed for sudo.  
Define in :scutil_sudo_passwd or check :scutil_sudo_failed_passwd for the correct failure response.", 
                                      hostname)
              channel.close
              sudo_passwd_state = :done
            else
              # NoOp for "\n"
            end
          else
            raise Scutil::Error.new("[#{conn.host}:#{channel.local_id}] Invalid connection state.", hostname)
          end
          
          # Only buffer some of the output before writing to disk (10M by default).
          if (odata.size >= Scutil.output_buffer_size)
            fh.write odata
            odata = ""
          end
        end
        
        channel.on_extended_data do |ch, type, data|
          print "on_extended_data: #{data.size}\n" if options[:scutil_verbose]
          edata += data
        end
        
        channel.on_close do |ch|
          print "[#{conn.host}:#{channel.local_id}] on_close\n" if options[:scutil_verbose]
        end
        
        channel.on_open_failed do |ch, code, desc|
          raise Scutil::Error.new("Failed to open channel: #{desc}", hostname, code) if !success
        end
        
        channel.on_request("exit-status") do |ch, data|
          exit_status = data.read_long
          print "[#{conn.host}:#{channel.local_id}] on_request(\"exit-status\"): #{exit_status}\n" if options[:scutil_verbose]
        end
        
        channel.exec(cmd)
      end
      
      conn.loop
      
      # Write whatever is left
      fh.write odata
      
      # Close the file or you'll chase red herrings for two hours...
      fh.close unless fh == $stdout
      
      # If extended_data was recieved there was a problem...
      raise Scutil::Error.new("Error: #{edata}", hostname, exit_status) unless (edata.empty?)
      
      # The return value of the remote command.
      return exit_status
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
      # <em>*NB:* This function currently calls the *blocking* Net::SCP#upload!
      # function rather than the *non-blocking* #upload function.  This is by
      # design and will most likely be changed in the near future.</em>
      def upload(hostname, username, local, remote, new_options={}, &progress)
        options = get_default_options
        options.merge! new_options
        conn = find_connection(hostname, username, false, options)
        conn.scp.upload!(local, remote, options, &progress)
      end
      
      # Convenience method for downloading files.  Only available if you have
      # Net::SCP.  This function simply calls Net::SCP#download! but reuses the
      # SSH connection if it's available.  All options and semantics are
      # identical to Scutil.exec_command and Net::SCP.  If _local_ is nil the
      # downloaded file will be stored in a string in memory returned by
      # +download+.
      #
      # <em>*NB:* This function currently calls the *blocking* Net::SCP#download!
      # function rather than the *non-blocking* #download function.  This is by
      # design and will most likely be changed in the near future.</em>
      def download(hostname, username, remote, local=nil, new_options={}, &progress)
        options = get_default_options
        options.merge! new_options
        conn = find_connection(hostname, username, false, options)
        conn.scp.download!(remote, local, options, &progress)
      end
    end
    
    # Check for an existing connection in the cache based on _hostname_.  If the
    # _hostname_ exists find a suitable connection.  Otherwise establish a
    # connection and add it to the pool.
    def find_connection(hostname, username, pty_needed, options)
      conn = nil
      begin
        if (Scutil.connection_cache.exists?(hostname))
          sys_conn = Scutil.connection_cache.fetch(hostname)
          print "[#{hostname}] Using existing connection\n" if options[:scutil_verbose]
          conn = sys_conn.get_connection(hostname, username, pty_needed, options)
        else
          sys_conn = SystemConnection.new(hostname, options)
          # Call get_connection first.  Don't add to cache unless established.
          conn = sys_conn.get_connection(hostname, username, pty_needed, options)
          print "[#{hostname}] Adding new connection to cache\n" if options[:scutil_verbose]
          Scutil.connection_cache << sys_conn
        end
      rescue Net::SSH::AuthenticationFailed => err
        raise Scutil::Error.new("Authenication failed for user: #{username}", hostname)
      rescue SocketError => err
        raise Scutil::Error.new(err.message, hostname)
      end
      return conn
    end
    
    private
    # Set the default options for connection.
    def get_default_options
      { 
        :scutil_verbose                  => false,
        :scutil_force_pty                => false,
        :scutil_pty_regex                => DEFAULT_PTY_REGEX,
        :scutil_sudo_passwd_regex        => DEFAULT_SUDO_PASSWD_REGEX,
        :scutil_sudo_passwd_failed_regex => DEFAULT_SUDO_PASSWD_FAILED_REGEX,
        :scutil_sudo_passwd              => nil
      }
    end
    
    def set_sudo_password_prompt(options)
      if (!options[:scutil_sudo_passwd_regex].nil? && 
          (options[:scutil_sudo_passwd_regex].kind_of? Regexp))
        return options[:scutil_sudo_passwd_regex]
      else
        raise Scutil::Error.new(":scutil_sudo_passwd_regex must be a kind of Regexp", hostname)
      end
    end
    
    def set_sudo_password_failed(options)
      if (!options[:scutil_sudo_passwd_failed_regex].nil? && 
          (options[:scutil_sudo_passwd_failed_regex].kind_of? Regexp))
        return options[:scutil_sudo_passwd_failed_regex]
      else
        raise Scutil::Error.new(":scutil_sudo_passwd_failed_regex must be a kind of Regexp", hostname)
      end
    end
    
    def method_missing(method, *args, &block)
      return if ((method == :download) || (method == :upload))
      super
    end
  end
end
