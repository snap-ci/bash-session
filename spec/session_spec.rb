require 'spec_helper'

describe Bash::Session do
  before(:each) do
    @session = Bash::Session.new
  end

  after(:each) do
    @session.close
  end

  it 'should run commands and show out put when it does not end in a new line' do
    @session.execute("echo -n hello") { |output| expect(output).to eq("hello") }
  end

  it 'should return the exit status of the command' do
    exit_status = @session.execute("true")
    expect(exit_status).to eq(0)

    exit_status = @session.execute("false")
    expect(exit_status).to eq(1)
  end

  it 'should run commands ending with comments' do
    exit_status = @session.execute("true # this is a comment") { |output| expect(output).to eq("") }
    expect(exit_status).to eq(0)
  end

  it 'should preserve the state of bash internal commands' do
    @session.execute("cd #{Dir.pwd}/spec")
    @session.execute("pwd") { |output| expect(output).to include("#{Dir.pwd}/spec") }
    @session.execute("cd ~")
    @session.execute("pwd") { |output| expect(output).to include(Dir.home) }
    @session.execute("echo $FOO") { |output| expect(output).to_not include("bar") }
    @session.execute("export FOO=bar")
    @session.execute("echo $FOO") { |output| expect(output).to include("bar") }
  end

  it 'should run multiple commands separated by a newline' do
    reader, writer = IO.pipe
    @session.execute("echo hi\necho bye", out: writer)
    writer.close
    expect(reader.read).to eq("hi\nbye\n")
  end

  it 'should wait for long running commands to complete and then exit' do
    reader, writer = IO.pipe
    exit_status = @session.execute("for i in {1..5}; do echo -n 'hello world '; sleep 1; done", out: writer)
    expect(exit_status).to eq(0)
    writer.close
    expect(reader.read).to eq("hello world "*5)
  end

  it 'should raise error when command does not generate any output within a default timeout period' do
    @session = Bash::Session.new(3)
    reader, writer = IO.pipe

    begin_time = Time.now
    expect do
      exit_status = @session.execute("echo hi; sleep 300; echo bye", out: writer)
    end.to raise_error(Bash::Session::TimeoutError, 'No output received for the last 3 seconds. Timing out...')
    writer.close
    end_time = Time.now

    expect(end_time - begin_time).to be_within(0.1).of(3)
    expect(reader.read_nonblock(1000)).to eq("hi\n")
  end

  it 'should raise error when command does not generate any output command specific timeout period' do
    @session = Bash::Session.new(1)
    reader, writer = IO.pipe

    begin_time = Time.now

    expect do
      exit_status = @session.execute("echo hi; sleep 300; echo bye", out: writer, timeout: 3)
    end.to raise_error(Bash::Session::TimeoutError, 'No output received for the last 3 seconds. Timing out...')
    end_time = Time.now

    writer.close

    expect(end_time - begin_time).to be_within(0.1).of(3)
    expect(reader.read_nonblock(1000)).to eq("hi\n")
  end

  it 'should not raise error when long running command is constantly generating output with default timeout' do
    @session = Bash::Session.new(3)
    reader, writer = IO.pipe

    exit_status = @session.execute("echo -n hi; for i in {1..6}; do sleep 1; echo -n .; done; echo bye", out: writer)
    writer.close

    expect(reader.read_nonblock(1000)).to eq("hi......bye\n")
  end

  it 'should not raise error when long running command is constantly generating output with a command specific timeout' do
    @session = Bash::Session.new(3)
    reader, writer = IO.pipe

    exit_status = @session.execute("echo -n hi; for i in {1..6}; do sleep 4; echo -n .; done; echo bye", out: writer, timeout: 5)
    writer.close

    expect(reader.read_nonblock(1000)).to eq("hi......bye\n")
  end
end
