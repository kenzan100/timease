require_relative "../time_easer"
require_relative "../adapters/mite"
require "minitest/autorun"

class TestTimeEase < Minitest::Test
  def setup
    input   = TimeEase::Input.new("10:00", "16:00", "12-25-2016", "RS Sprint6, GoodTravel(1.5)")
    @parser = TimeEase::Parser.new(input)
  end

  def test_post
    # parsed = @parser.parse
    # TimeEase::Adapter::Mite.new(parsed).post
  end

  def test_revparse
    parsed_entries = @parser.parse
    input_entries = TimeEase::RevParser.new(parsed_entries).parse
    expected = { start_time: "10:00", end_time: "16:00", date: "2016-12-25", dones: ["RS Sprint6(4.5)", "GoodTravel (1.5)"] }
    assert_equal 1, input_entries.size
    assert_equal expected, input_entries.first.to_h
  end

  def test_parse
    parsed = @parser.parse
    mite_body = TimeEase::Adapter::Mite.new(parsed).request_bodies
    expected = [
      {
        time_entry: {
          date_at:    "2016-12-25",
          minutes:    270,
          project_id: 234,
          service_id: 1,
          note: "RS Sprint6"
        }
      },
      {
        time_entry: {
          date_at:    "2016-12-25",
          minutes:    90,
          project_id: 123,
          service_id: nil,
          note: "GoodTravel"
        }
      }
    ]
    assert_equal expected, mite_body
  end
end
