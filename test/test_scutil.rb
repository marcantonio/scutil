#!/usr/bin/ruby -I../lib -I. -w

require 'test/unit'
require 'scutil'
require 'stringio'

class TestScutil < Test::Unit::TestCase
  TRUE_COMMAND  = '/bin/true'
  FALSE_COMMAND = '/bin/false'
  FAKE_COMMAND  = '/bin/no_such_command'

  @hostname = nil
  @port = nil
  @user = nil
  
  class << self
    attr_accessor :hostname,:port,:user
  end
  
  def divert_stdout
    @tmp_output = $stdout
    $stdout = StringIO.new
  end
  
  def revert_stdout
    @output = $stdout
    $stdout = @tmp_output
  end
  
  def setup
    @output = nil
    @tmp_output = nil
    @exec = Scutil::Exec.new(TestScutil.hostname, TestScutil.user, 
                             { :port => TestScutil.port,
                               :scutil_verbose => false })
  end
  
  def teardown
    @exec = nil
    Scutil.connection_cache.remove_all
  end
  
  def test_object_initialized
    assert_not_nil @exec
  end
  
  def test_object_is_correct_class
    assert_instance_of Scutil::Exec, @exec
  end
  
  def test_exec_doesnt_raise_an_exception
    assert_nothing_raised do
      @exec.exec_command(TRUE_COMMAND)
    end
  end
  
  def test_run_successful_command
    retval = @exec.exec_command(TRUE_COMMAND)
    assert_equal 0, retval
  end
  
  def test_run_failed_command
    retval = @exec.exec_command(FALSE_COMMAND)
    assert_not_equal 0, retval
  end
  
  def test_added_to_cache
    @exec.exec_command(TRUE_COMMAND)
    assert(Scutil.connection_cache.exists?(TestScutil.hostname))
  end
  
  def test_exec_command_output
    divert_stdout
    @exec.exec_command('echo "alpha"')
    # Scutil.exec_command(TestScutil.hostname, TestScutil.user, 'echo "alpha"', nil, { :port => TestScutil.port })
    revert_stdout
    assert_equal "alpha", @output.string.chomp
  end
  
  def test_clear_connection
    @exec.exec_command(TRUE_COMMAND)
    Scutil.clear!(TestScutil.hostname)
    assert(!Scutil.connection_cache.exists?(TestScutil.hostname))
  end
  
  def test_exception_raised
    assert_raises(Scutil::Error) do
      @exec.exec_command(FAKE_COMMAND)
    end
  end
  
  def test_pty_not_requested
    @exec.exec_command(TRUE_COMMAND)
    conn = Scutil.connection_cache.fetch(TestScutil.hostname)
    assert_not_nil(conn.connection)
    assert_instance_of(Net::SSH::Connection::Session, conn.connection)
    assert_nil(conn.pty_connection)
  end
  
  def test_pty_requested
    @exec.exec_command("sudo " + TRUE_COMMAND)
    conn = Scutil.connection_cache.fetch(TestScutil.hostname)
    assert_not_nil(conn.pty_connection)
    assert_instance_of(Net::SSH::Connection::Session, conn.pty_connection)
    assert_nil(conn.connection)
  end

  def test_option_pty_regex
    @exec.exec_command("env " + TRUE_COMMAND, nil, { :scutil_pty_regex => /^env / })
    conn = Scutil.connection_cache.fetch(TestScutil.hostname)
    assert_not_nil(conn.pty_connection)
    assert_instance_of(Net::SSH::Connection::Session, conn.pty_connection)
    assert_nil(conn.connection)    
  end
  
  def test_option_verbose_set_and_local_options_take_precedence
    divert_stdout
    @exec.exec_command(TRUE_COMMAND, nil, { :scutil_verbose => true })
    revert_stdout
    assert_match(/\[#{TestScutil.hostname}\]/, @output.string)
  end

  def test_option_force_pty
    @exec.exec_command(TRUE_COMMAND, nil, { :scutil_force_pty => true })
    conn = Scutil.connection_cache.fetch(TestScutil.hostname)
    assert_not_nil(conn.pty_connection)
    assert_instance_of(Net::SSH::Connection::Session, conn.pty_connection)
    assert_nil(conn.connection)
  end
  
  def test_alter_options
    divert_stdout
    @exec.exec_command(TRUE_COMMAND)
    revert_stdout
    assert_not_match(/\[#{TestScutil.hostname}\]/, @output.string)
    
    @exec.set_options({ :scutil_verbose => true })
    
    divert_stdout
    @exec.exec_command(TRUE_COMMAND)
    revert_stdout
    assert_match(/\[#{TestScutil.hostname}\]/, @output.string)
  end
end

class TestScutilAlt < Test::Unit::TestCase
  TRUE_COMMAND  = '/bin/true'
  FALSE_COMMAND = '/bin/false'
  FAKE_COMMAND  = '/bin/no_such_command'

  @hostname = nil
  @port = nil
  @user = nil
  
  class << self
    attr_accessor :hostname,:port,:user
  end
  
  def divert_stdout
    @tmp_output = $stdout
    $stdout = StringIO.new
  end
  
  def revert_stdout
    @output = $stdout
    $stdout = @tmp_output
  end
  
  def setup
    @output = nil
    @tmp_output = nil
  end
  
  def test_exec_doesnt_raise_an_exception
    assert_nothing_raised do
      Scutil.exec_command(TestScutil.hostname, TestScutil.user, TRUE_COMMAND, nil, { :port => TestScutil.port })
    end
  end
  
  def test_run_successful_command
    retval = Scutil.exec_command(TestScutil.hostname, TestScutil.user, TRUE_COMMAND, nil, { :port => TestScutil.port })
    assert_equal 0, retval
  end
  
  def test_run_failed_command
    retval = Scutil.exec_command(TestScutil.hostname, TestScutil.user, FALSE_COMMAND, nil, { :port => TestScutil.port })
    assert_not_equal 0, retval
  end
  
  def test_added_to_cache
    Scutil.exec_command(TestScutil.hostname, TestScutil.user, TRUE_COMMAND, nil, { :port => TestScutil.port })
    assert(Scutil.connection_cache.exists?(TestScutil.hostname))
  end
  
  def test_exec_command_output
    divert_stdout
    Scutil.exec_command(TestScutil.hostname, TestScutil.user, 'echo "alpha"', nil, { :port => TestScutil.port })
    revert_stdout
    assert_equal "alpha", @output.string.chomp
  end

  def teardown
    Scutil.connection_cache.remove_all
  end
end

# XXX: This breaks --name, et al.
if ARGV[0].nil?
  puts "Usage: #{$0} host[:port]"
  exit(1)
end

(TestScutil.hostname, TestScutil.port) = ARGV[0].split(':')
TestScutil.user = 'mas'
