
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
