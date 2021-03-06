module Delayed
  class Worker
    SLEEP = 5

    def initialize(options={})
      @quiet = options[:quiet]
      @logger = options[:logger] ? options[:logger] : RAILS_DEFAULT_LOGGER
      Delayed::Job.min_priority = options[:min_priority] if options.has_key?(:min_priority)
      Delayed::Job.max_priority = options[:max_priority] if options.has_key?(:max_priority)
    end                                                                          

    def start
      say "*** Starting job worker #{Delayed::Job.worker_name}"
      
      file = File.new("#{RAILS_ROOT}/tmp/pids/Worker_#{Process.pid}.pid", "w+")
      file.puts "Rake Task Started #{Time.now}"
      file.puts "PID: #{Process.pid}"
      file.close      

      trap('TERM') { say "Exiting...#{Delayed::Job.worker_name}"; $exit = true }
      trap('INT')  { say "Exiting...#{Delayed::Job.worker_name}"; $exit = true }

      loop do
        result = nil

        realtime = Benchmark.realtime do
          result = Delayed::Job.work_off
        end

        count = result.sum

        if $exit
          Delayed::Job.clear_locks!
          break
        end

        if count.zero?
          sleep(SLEEP)
        else
          say "#{count} jobs processed at %.4f j/s, %d failed ..." % [count / realtime, result.last]
        end

        if $exit
          Delayed::Job.clear_locks!
          break
        end
      end
    end
    
    def say(text)
      puts text unless @quiet
      @logger.info text
    end

  end
end
