class Antenna
  attr_accessor :coordinates, :file_code
  attr_reader :size

  def initialize(number)
    @number = number
    @coordinates = coordinates_by_number
    @file_code = file_code_by_number
    @size = [120, 85]
  end



  private

  def file_code_by_number
    (((@number - 1) / 4).floor + 1).to_s + "-" + ((@number - 1) % 4 + 1).to_s
  end

  def coordinates_by_number
    Point.new(70 + ((@number - 1) / 4).floor * 120, 70 + ((@number - 1) % 4) * 120)
  end
end