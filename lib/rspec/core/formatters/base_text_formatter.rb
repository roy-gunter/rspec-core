require 'rspec/core/formatters/base_formatter'

module RSpec
  module Core
    module Formatters

      class BaseTextFormatter < BaseFormatter

        def message(message)
          output.puts message
        end

        # def dump_failures
        #   return if failed_examples.empty?
        #   output.puts
        #   output.puts "Failures:"
        #   failed_examples.each_with_index do |example, index|
        #     output.puts
        #     # blocked_fixed?(example) ? dump_blocked_fixed(example, index) : dump_failure(example, index)
        #     pending_fixed?(example) ? dump_pending_fixed(example, index) : dump_failure(example, index)
        #     dump_backtrace(example)
        #   end
        # end

        def dump_failures
          return if failed_examples.empty?
          output.puts
          output.puts "Failures:"
          failed_examples.each_with_index do |example, index|
            output.puts
            if pending_fixed?(example)
              dump_pending_fixed(example, index)
            elsif blocked_fixed?(example)
              dump_blocked_fixed(example, index)
            else
              dump_failure(example, index)
            end
            dump_backtrace(example)
          end
        end

        def colorise_summary(summary)
          if failure_count > 0
            red(summary)
          elsif blocked_count > 0
            magenta(summary)
          elsif pending_count > 0
            yellow(summary)
          elsif manual_count > 0
            green(summary)
          else
            green(summary)
          end
        end

        def dump_summary(duration, example_count, failure_count, pending_count, manual_count, blocked_count)
          super(duration, example_count, failure_count, pending_count, manual_count, blocked_count)
          # Don't print out profiled info if there are failures, it just clutters the output
          dump_profile if profile_examples? && failure_count == 0
          output.puts "\nFinished in #{format_duration(duration)}\n"
          output.puts colorise_summary(summary_line(example_count, failure_count, pending_count, manual_count, blocked_count))
          dump_commands_to_rerun_failed_examples
        end

        def dump_commands_to_rerun_failed_examples
          return if failed_examples.empty?
          output.puts
          output.puts("Failed examples:")
          output.puts

          failed_examples.each do |example|
            output.puts(red("rspec #{RSpec::Core::Metadata::relative_path(example.location)}") + " " + cyan("# #{example.full_description}"))
          end
        end

        def dump_profile
          sorted_examples = examples.sort_by {|example|
            example.execution_result[:run_time] }.reverse.first(10)

          total, slows = [examples, sorted_examples].map {|exs|
            exs.inject(0.0) {|i, e| i + e.execution_result[:run_time] }}

          time_taken = slows / total
          percentage = '%.1f' % ((time_taken.nan? ? 0.0 : time_taken) * 100)

          output.puts "\nTop #{sorted_examples.size} slowest examples (#{format_seconds(slows)} seconds, #{percentage}% of total time):\n"

          sorted_examples.each do |example|
            output.puts "  #{example.full_description}"
            output.puts cyan("    #{red(format_seconds(example.execution_result[:run_time]))} #{red("seconds")} #{format_caller(example.location)}")
          end
        end

        def summary_line(example_count, failure_count, pending_count, manual_count, blocked_count)
          summary = pluralize(example_count, "example")
          summary << ", " << pluralize(failure_count, "failure")
          summary << ", #{blocked_count} blocked by defect" if blocked_count > 0
          summary << ", " << pluralize(manual_count,"manual test") if manual_count > 0
          summary << ", #{pending_count} pending automation" if pending_count > 0
          summary
        end

        def dump_pending
          unless pending_examples.empty?
            output.puts
            output.puts "Pending:"
            pending_examples.each do |pending_example|
              output.puts yellow("  #{pending_example.full_description}")
              output.puts cyan("    # #{pending_example.execution_result[:pending_message]}")
              output.puts cyan("    # #{format_caller(pending_example.location)}")
              if pending_example.execution_result[:exception] \
                && RSpec.configuration.show_failures_in_pending_blocks?
                dump_failure_info(pending_example)
                dump_backtrace(pending_example)
              end
            end
          end
        end

        def dump_manual
          unless manual_examples.empty?
            output.puts
            output.puts "Manual:"
            manual_examples.each do |manual_example|
              output.puts blue("  #{manual_example.full_description}")
              output.puts cyan("    # #{manual_example.execution_result[:manual_message]}")
              output.puts cyan("    # #{format_caller(manual_example.location)}")
              if manual_example.execution_result[:exception] \
                && RSpec.configuration.show_failures_in_manual_blocks?
                dump_failure_info(manual_example)
                dump_backtrace(manual_example)
              end
            end
          end
        end

        def dump_blocked
          unless blocked_examples.empty?
            output.puts
            output.puts "Blocked by defect:"
            blocked_examples.each do |blocked_example|
              output.puts magenta("  #{blocked_example.full_description}")
              output.puts cyan("    # #{blocked_example.execution_result[:blocked_message]}")
              output.puts cyan("    # #{format_caller(blocked_example.location)}")
              if blocked_example.execution_result[:exception] \
                && RSpec.configuration.show_failures_in_blocked_blocks?
                dump_failure_info(blocked_example)
                dump_backtrace(blocked_example)
              end
            end
          end
        end

        def seed(number)
          output.puts
          output.puts "Randomized with seed #{number}"
          output.puts
        end

        def close
          output.close if IO === output && output != $stdout
        end

      protected

        def color(text, color_code)
          color_enabled? ? "#{color_code}#{text}\e[0m" : text
        end

        def bold(text)
          color(text, "\e[1m")
        end

        def red(text)
          color(text, "\e[31m")
        end

        def green(text)
          color(text, "\e[32m")
        end

        def yellow(text)
          color(text, "\e[33m")
        end

        def blue(text)
          color(text, "\e[34m")
        end

        def magenta(text)
          color(text, "\e[35m")
        end

        def cyan(text)
          color(text, "\e[36m")
        end

        def white(text)
          color(text, "\e[37m")
        end

        def short_padding
          '  '
        end

        def long_padding
          '     '
        end

      private

        def format_caller(caller_info)
          backtrace_line(caller_info.to_s.split(':in `block').first)
        end

        def dump_backtrace(example)
          format_backtrace(example.execution_result[:exception].backtrace, example).each do |backtrace_info|
            output.puts cyan("#{long_padding}# #{backtrace_info}")
          end
        end

        def dump_pending_fixed(example, index)
          output.puts "#{short_padding}#{index.next}) #{example.full_description} FIXED"
          output.puts cyan("#{long_padding}Expected pending '#{example.metadata[:execution_result][:pending_message]}' to fail. No Error was raised.")
        end

        def dump_blocked_fixed(example, index)
          output.puts "#{short_padding}#{index.next}) #{example.full_description} -- DEFECT FIXED!"
          output.puts cyan("#{long_padding}Expected test to fail due to defect '#{example.metadata[:execution_result][:blocked_message]}'.")
          output.puts cyan("#{long_padding}No Error was raised. Check if issue has been corrected.")
        end

        def blocked_fixed?(example)
          example.execution_result[:exception].blocked_fixed?
        end

        def pending_fixed?(example)
          example.execution_result[:exception].pending_fixed?
        end

        def dump_failure(example, index)
          output.puts "#{short_padding}#{index.next}) #{example.full_description}"
          dump_failure_info(example)
        end

        def dump_failure_info(example)
          exception = example.execution_result[:exception]
          output.puts "#{long_padding}#{red("Failure/Error:")} #{red(read_failed_line(exception, example).strip)}"
          output.puts "#{long_padding}#{red(exception.class.name << ":")}" unless exception.class.name =~ /RSpec/
          exception.message.to_s.split("\n").each { |line| output.puts "#{long_padding}  #{red(line)}" } if exception.message
          if shared_group = find_shared_group(example)
            dump_shared_failure_info(shared_group)
          end
        end

        def dump_shared_failure_info(group)
          output.puts "#{long_padding}Shared Example Group: \"#{group.metadata[:shared_group_name]}\" called from " +
            "#{backtrace_line(group.metadata[:example_group][:location])}"
        end

        def find_shared_group(example)
          group_and_parent_groups(example).find {|group| group.metadata[:shared_group_name]}
        end

        def group_and_parent_groups(example)
          example.example_group.parent_groups + [example.example_group]
        end
      end
    end
  end
end
