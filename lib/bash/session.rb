require "bash/session/version"
require 'securerandom'
require 'open3'

module Bash
  class Session
    class TimeoutError < StandardError; end

    def initialize(timeout=nil)
      start_session
      @timeout = timeout
      @separator = SecureRandom.hex
    end

    def execute(command, options={}, &callback)
      exit_status = nil
      out = options[:out]

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
          out.puts data if out
        rescue IO::WaitReadable
          ready = IO.select([@outstr], nil, nil, @timeout)
          unless ready
            raise TimeoutError.new("No output received for the last #{@timeout} seconds. Timing out..")
          else
            retry
          end
        end
      end

      exit_status.to_i
    end

    private

    def start_session
      @stdin, @outstr, @wait_thr = Open3.popen2e("bash")
    end
  end
end
