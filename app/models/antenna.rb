class Antenna
  attr_reader :coverage_zone_width, :coverage_zone_height
  attr_accessor :coordinates, :file_code

  def initialize(number, coverage_zone = [0, 0])
    @number = number
    @coordinates = coordinates_by_number
    @file_code = file_code_by_number
    @coverage_zone_width = coverage_zone[0]
    @coverage_zone_height = coverage_zone[1]
  end



  private

  def file_code_by_number
    (((@number - 1) / 4).floor + 1).to_s + "-" + ((@number - 1) % 4 + 1).to_s
  end

  def coordinates_by_number
    Point.new(70 + ((@number - 1) / 4).floor * 120, 70 + ((@number - 1) % 4) * 120)
  end
end