#!/usr/bin/ruby -I../lib -I. -w

require 'test/unit'
require 'scutil'
require 'stringio'

class TestScutil < Test::Unit::TestCase
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
    @exec = Scutil::Exec.new(TestScutil.hostname, TestScutil.user, { :port => TestScutil.port })
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
      @exec.exec_command('/bin/true')
    end
  end
  
  def test_run_successful_command
    retval = @exec.exec_command('/bin/true')
    assert_equal 0, retval
  end
  
  def test_run_failed_command
    retval = @exec.exec_command('/bin/false')
    assert_not_equal 0, retval
  end
  
  def test_added_to_cache
    @exec.exec_command('/bin/true')
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
    @exec.exec_command('/bin/true')
    Scutil.clear!(TestScutil.hostname)
    assert(!Scutil.connection_cache.exists?(TestScutil.hostname))
  end
  
  def test_exception_raised
    assert_raises(Scutil::Error) do
      @exec.exec_command('/bin/not_such_command')
    end
  end
end

=begin
class TestScutil2 < Test::Unit::TestCase
  include ScutilTestsCommon
  
  def setup
    p self
    @hostname = ARGV[0]
    @port = ARGV[1]
    @user = 'mas'
    module_setup
    @exec = Scutil::Exec.new(@hostname, @user, { :port => @port })
  end
  
  def test_run_command
    divert_stdout
    retval = @exec.exec_command('echo "bravo"')
    revert_stdout
    assert_equal "bravo", @output.string.chomp
  end
end  
=end
  
if ARGV[0].nil?
  puts "Usage: #{$0} host[:port]"
  exit(1)
end

(TestScutil.hostname, TestScutil.port) = ARGV[0].split(':')
TestScutil.user = 'mas'
