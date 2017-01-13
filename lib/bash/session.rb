require "bash/session/version"
require 'securerandom'
require 'open3'

module Bash
  class Session
    class TimeoutError < StandardError; end

    attr_reader :default_timeout

    def initialize(default_timeout=nil)
      start_session
      @default_timeout = default_timeout
      @separator = SecureRandom.hex
    end

    def execute(command, options={}, &callback)
      exit_status = nil
      out = options[:out]
      timeout = options[:timeout] || @default_timeout

      cmd = command.dup
      cmd << ";" if cmd !~ /[;&]$/
      cmd << "\n" if cmd =~ /#/
      cmd << %Q{DONTEVERUSETHIS=$?; echo "\n#{@separator} $DONTEVERUSETHIS"; echo "exit $DONTEVERUSETHIS"|sh}

      @stdin.puts(cmd)

      until exit_status do
        begin
          data = @outstr.read_nonblock(160000)
          if data.strip =~ /^#{@separator} (\d+)\s*/
            exit_status = $1
            data.gsub!(/\n^#{@separator} (\d+)\s*$/, '')
          end
          callback.call(data) if callback
          out.write data if out
        rescue IO::WaitReadable
          ready = IO.select([@outstr], nil, nil, timeout)
          unless ready
            raise TimeoutError.new("No output received for the last #{timeout} seconds. Timing out...")
          else
            retry
          end
        end
      end

      exit_status.to_i
    end

    def close
      return unless @wait_thr.alive?
      return if (Process.kill('TERM', @wait_thr.pid) rescue nil)
      return unless @wait_thr.alive?
      return if (Process.kill('KILL', @wait_thr.pid) rescue nil)
      return unless @wait_thr.alive?
      raise "Could not kill process(PID #{@wait_thr.pid})"
    end

    private

    def start_session
      @stdin, @outstr, @wait_thr = Open3.popen2e("bash --login")
    end
  end
end
