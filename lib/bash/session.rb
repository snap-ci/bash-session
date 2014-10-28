require "bash/session/version"
require 'securerandom'
require 'pty'

module Bash
  class Session
    def initialize
      start_session
      @separator = SecureRandom.hex
    end

    def execute(command, options={}, &callback)
      exit_status = nil
      out = options[:out]

      cmd = command.dup
      cmd << ";" if cmd !~ /[;&]$/
      cmd << %Q{ DONTEVERUSETHIS=$?; echo "\n#{@separator} $DONTEVERUSETHIS"; echo "exit $DONTEVERUSETHIS"|sh}

      @write.puts(cmd)
      until exit_status do
        begin
          data = @master.read_nonblock(160000)
          if data.strip =~ /^#{@separator} (\d+)\s*/
            exit_status = $1
            data.gsub!(/^#{@separator} (\d+)\s*/, '')
          end
          callback.call(data) if callback
          out.puts data if out
        rescue IO::WaitReadable
          IO.select([@master])
          retry
        end
      end

      exit_status.to_i
    end

    private

    def start_session
      @master, slave = PTY.open
      read, @write = IO.pipe
      spawn("bash", in: read, out: slave, err: slave)
      read.close
      slave.close
    end
  end
end
