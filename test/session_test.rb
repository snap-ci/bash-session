require_relative 'test_helper'

class BashSessionTest < Minitest::Test

  def setup
    @session = Bash::Session.new
  end

  def teardown
    @session.close
  end

  def test_run_commands_and_show_out_put_when_it_does_not_end_in_a_new_line
    @session.execute("echo -n hello") { |output| assert_equal "hello", output }
  end

  def test_return_the_exit_status_of_the_command
    exit_status = @session.execute("true")
    assert_equal 0, exit_status

    exit_status = @session.execute("false")
    assert_equal 1, exit_status
  end

  def test_run_commands_ending_with_comments
    exit_status = @session.execute("true # this is a comment") { |output| assert_equal "", output }
    assert_equal 0, exit_status
  end

  def test_uses_same_session_and_preserves_state_through_sequential_commands
    assert_success_with_output("cd #{Dir.pwd}/spec")
    assert_success_with_output("pwd") { |output| assert_match("#{Dir.pwd}/spec", output) }
    assert_success_with_output("cd ~")
    assert_success_with_output("pwd") { |output| assert_match(Dir.home, output) }
    assert_success_with_output("echo $FOO") { |output| refute_match("bar", output) }
    assert_success_with_output("export FOO=bar")
    assert_success_with_output("echo $FOO") { |output| assert_match("bar", output) }
  end

  def test_run_multiple_commands_separated_by_a_newline
    reader, writer = IO.pipe
    @session.execute("echo hi\necho bye", out: writer)
    writer.close
    assert_equal "hi\nbye\n", reader.read
  end

  def test_wait_for_long_running_commands_to_complete_and_then_exit
    reader, writer = IO.pipe
    exit_status = @session.execute("for i in {1..5}; do echo -n 'hello world '; sleep 1; done", out: writer)
    assert_equal 0, exit_status
    writer.close
    assert_equal "hello world "*5, reader.read
  end

  def test_raise_error_when_command_does_not_generate_any_output_within_a_default_timeout_period
    @session = Bash::Session.new(3)
    reader, writer = IO.pipe

    begin_time = Time.now
    e = assert_raises(Bash::Session::TimeoutError) do
      @session.execute("echo hi; sleep 300; echo bye", out: writer)
    end
    end_time = Time.now

    writer.close

    # expect(end_time - begin_time).to be_within(0.1).of(3)
    assert_equal 'No output received for the last 3 seconds. Timing out...', e.message
    assert_equal "hi\n", reader.read
  end

  def test_raise_error_when_command_does_not_generate_any_output_command_specific_timeout_period
    @session = Bash::Session.new(1)
    reader, writer = IO.pipe

    begin_time = Time.now
    e = assert_raises(Bash::Session::TimeoutError) do
      @session.execute("echo hi; sleep 300; echo bye", out: writer, timeout: 3)
    end
    end_time = Time.now

    writer.close

    # expect(end_time - begin_time).to be_within(0.1).of(3)
    assert_equal 'No output received for the last 3 seconds. Timing out...', e.message
    assert_equal "hi\n", reader.read
  end

  def test_not_raise_error_when_long_running_command_is_constantly_generating_output_with_default_timeout
    @session = Bash::Session.new(3)
    reader, writer = IO.pipe

    exit_status = @session.execute("echo -n hi; for i in {1..6}; do sleep 1; echo -n .; done; echo bye", out: writer)
    writer.close

    assert_equal 0, exit_status
    assert_equal "hi......bye\n", reader.read
  end

  def test_not_raise_error_when_long_running_command_is_constantly_generating_output_with_a_command_specific_timeout
    @session = Bash::Session.new(3)
    reader, writer = IO.pipe

    exit_status = @session.execute("echo -n hi; for i in {1..6}; do sleep 4; echo -n .; done; echo bye", out: writer, timeout: 5)
    writer.close

    assert_equal "hi......bye\n", reader.read
  end

  def test_start_a_non_interactive_login_shell_session
    exit_status = @session.execute("[[ $- != *i* ]]")
    assert_equal 0, exit_status

    exit_status = @session.execute("shopt -q login_shell")
    assert_equal 0, exit_status
  end

  def assert_success_with_output(command, &block)
    output = ""
    status = @session.execute(command) { |out| output = out }
    assert_equal 0, status, "command #{command} failed with status #{status}"
    yield output if block_given?
  end
end
