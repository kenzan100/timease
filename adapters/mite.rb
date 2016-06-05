require "byebug"
require "yaml"
require "json"
require "rest-client"

module TimeEase::Adapter
  class Mite
    def initialize(parsed_output)
      @parsed = parsed_output
    end

    def post
      request_bodies.each do |req_body|
        RestClient.post "#{ENV['MITE_API_HOST']}/time_entries.json",
          req_body.to_json,
          { content_type: :json,
            accept: :json,
            "X-MiteApiKey": ENV["MITE_API_KEY"] }
      end
    end

    def request_bodies
      @parsed.map do |entry|
        {
          time_entry: {
            date_at:    entry.start_at.strftime("%Y-%m-%d"),
            minutes:    ((entry.end_at - entry.start_at) / 60.0).to_i,
            project_id: project_id(entry),
            service_id: service_id(entry),
            note: "#{entry.pj_name} #{entry.task_name}".strip
          }
        }
      end
    end

    private

    def project_id(entry)
      detect_id(entry, "projects", "pj_name")
    end

    def service_id(entry)
      detect_id(entry, "services", "task_name")
    end

    def detect_id(entry, key, prop)
      mapping[key].detect(->{{}}) { |record|
        record["names"].include? entry.send(prop)
      }["id"]
    end

    def mapping
      @mapping ||= YAML.load_file("data/mite_mapping.yml")
    end
  end
end
