require "test_helper"

class TimeEaseComplexTest < Minitest::Test
  def setup
    input   = TimeEase::Input.new("10:00", "16:00", "12-25-2016", "RS Sprint6(5), GoodTravel(1.5)")
    @parser = TimeEase::Parser.new(input)
  end

  def test_parse
    parsed = @parser.parse
    expected = [
      TimeEase::Output.new(Chronic.parse("2016-12-25 10:00"), Chronic.parse("2016-12-25 13:00"), false, "RS", "Sprint"),
      TimeEase::Output.new(Chronic.parse("2016-12-25 13:00"), Chronic.parse("2016-12-25 16:00"), false, "RS", "Sprint") 
    ]
    assert_equal expected, parsed
  end
end
