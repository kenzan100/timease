require "timease/version"
require "adapters/mite"
require "chronic"
require "ostruct"

module TimeEase
  Input  = Struct.new(:start_time, :end_time, :date, :dones) do
    def valid?
      [start_time, end_time, date, dones].none?{ |a| a.nil? || a.empty? }
    end
  end
  Output = Struct.new(:start_at, :end_at, :exact, :pj_name, :task_name)

  class RevParser
    attr_reader :parsed_entries

    def initialize(parsed_outputs)
      @parsed_entries = parsed_outputs
    end

    def parse
      parsed_entries.group_by { |e| e.start_at.to_date }.map { |date, entries|
        start_time = l_time(entries.min_by { |e| e.start_at }.start_at)
        end_time   = l_time(entries.max_by { |e| e.end_at }.end_at)
        dones = entries.sort_by { |e| e.start_at }.map { |e|
          dur = (e.end_at - e.start_at) / 3600
          "#{e.pj_name} #{e.task_name}(#{dur})"
        }
        Input.new(start_time, end_time, l_date(date), dones)
      }
    end

    private

    def l_time(time)
      time.strftime("%H:%M")
    end

    def l_date(time)
      time.strftime("%Y-%m-%d")
    end
  end

  class Parser
    def initialize(input)
      @input = input
    end

    def parse
      projects
    end

    private
    attr_reader :input

    def projects
      hours_fixed = tmp_entries.map(&:time_in_hour).reduce(:+)
      if (total_hour - hours_fixed) < 0
        tmp_entries.map { |t| t.time_in_hour = total_hour / tmp_entries.size.to_f }
      else
        entries_unfixed_time = tmp_entries.select{ |t| t.time_in_hour <= 0 }
        entries_unfixed_time.map { |t| t.time_in_hour = (total_hour - hours_fixed) / entries_unfixed_time.size.to_f }
      end
      add_time_range!(tmp_entries, diff: 0)
    end

    def add_time_range!(tmp_entries, diff:)
      t, *rest = tmp_entries
      return [] if t.nil?
      dur = t.time_in_hour * 3600
      this_start_at = start_at + diff
      output = Output.new(
        this_start_at,
        (this_start_at + dur),
        false,
        t.pj,
        t.task
      )
      [output] + add_time_range!(rest, diff: diff + dur)
    end

    def tmp_entries
      @tmp_entries ||= entries.map { |ent|
        pj_name_ab, task_name_ab, time_in_hour = ent.match(reg)[1..3]
        OpenStruct.new(pj: pj_name_ab, task: task_name_ab, time_in_hour: time_in_hour.to_f)
      }
    end

    def total_hour
      (end_at- start_at) / 3600.0
    end

    def start_at
      Chronic.parse("#{input.date} #{input.start_time}")
    end

    def end_at
      Chronic.parse("#{input.date} #{input.end_time}")
    end

    def reg
      /(\w+)\s*(\w*)\s*\(?([\w\.]+)?\)?/
    end

    def entries
      input.dones.split(",").map(&:strip)
    end
  end
end
