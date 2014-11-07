require 'spec_helper'

describe Bash::Session do
  before(:each) do
    @session = Bash::Session.new
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

  it 'should wait for long running commands to complete and then exit' do
    reader, writer = IO.pipe
    exit_status = @session.execute("for i in {1..5}; do echo -n 'hello world '; sleep 1; done", out: writer)
    expect(exit_status).to eq(0)
    writer.close
    expect(reader.read).to eq("hello world "*5)
  end
end
