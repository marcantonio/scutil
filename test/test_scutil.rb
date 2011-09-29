#!/usr/bin/ruby -I../lib -w

require 'test/unit'
require 'scutil'
require 'stringio'

class TestScutil < Test::Unit::TestCase
  def setup
    @hostname = ARGV[0]
    @port = ARGV[1]
    @user = 'mas'
    @exec = Scutil::Exec.new(@hostname, @user, 
                             { :port => @port,
                               # :keys => '~mas/.ssh/id_rsa', 
                             })
    @output = nil
    @t_output = nil
  end
  
  def divert_stdout
    @t_output = $stdout
    $stdout = StringIO.new
  end
  
  def revert_stdout
    @output = $stdout
    $stdout = @t_output
  end
  
  def test_basic_exec_command
    divert_stdout
    Scutil.exec_command(@hostname, 'mas', 'echo "alpha"', nil, { :port => @port })
    revert_stdout
    assert_equal "alpha", @output.string.chomp
    assert(Scutil.connection_cache.exists?(@hostname))
  end
  
  def test_added_to_cache
    
  end
  
  def test_exception
    Scutil.clear!(@hostname)
    assert_raises(Scutil::Error) do
      Scutil.exec_command(@hostname, 'ma', 'id', nil, { :port => @port })
    end
  end
  
  def test_initialize_exec_object_instance
    assert_not_nil @exec
  end
  
  def test_is_correct_instance
    assert_instance_of Scutil::Exec, @exec
  end
  
  def test_run_command_instance
    divert_stdout
    retval = @exec.exec_command('echo "bravo"')
    revert_stdout
    assert_equal "bravo", @output.string.chomp
  end
  
  def test_run_successful_command_instance
    retval = @exec.exec_command('/bin/true')
    assert_equal 0, retval
  end
  
  def test_run_failed_command_instance
    retval = @exec.exec_command('/bin/false')
    assert_not_equal 0, retval
  end
end

if ARGV[1].nil?
  puts "Usage: #{$0} host1 [host2 host3] port"
  exit(1)
end
