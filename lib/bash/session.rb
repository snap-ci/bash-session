require "bash/session/version"
require 'securerandom'
require 'pty'

module Bash
  class Session
    def initialize
      start_session
      @separator = SecureRandom.hex
    end

    def execute(command, options={})
      exit_status = 0
      out = options[:out] || STDOUT
      cmd = command.dup
      cmd << ";" if cmd !~ /[;&]$/
      cmd << " DONTEVERUSETHIS=$?; echo #{@separator} $DONTEVERUSETHIS; echo \"exit $DONTEVERUSETHIS\"|sh"

      @write.puts(cmd)
      loop do
        data = @master.gets
        if data.strip =~ /#{@separator} (\d+)$/
          exit_status = $1
          break
        else
          out.puts data
        end
      end

      exit_status
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
