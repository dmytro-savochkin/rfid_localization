class Antenna
  attr_reader :coverage_zone_width, :coverage_zone_height, :number
  attr_reader :big_coverage_zone_width, :big_coverage_zone_height
  attr_reader :coverage_zone_ratio, :big_coverage_zone_ratio
  attr_accessor :coordinates, :rotation, :file_code

  ERROR_LIMITS = {
      :rss => 100.0,
      :rr => 100.0,
      :a => 0.7
  }


  def initialize(number, coverage_zone = [0, 0], big_coverage_zone = [0, 0], coordinates = nil, rotation = Math::PI / 4)
    @number = number.to_i
		if coordinates
			@coordinates = coordinates
		else
			@coordinates = coordinates_by_number
		end
    @file_code = file_code_by_number
    @coverage_zone_width = coverage_zone[0]
    @coverage_zone_height = coverage_zone[1]
		@coverage_zone_ratio = coverage_zone[0].to_f / coverage_zone[1]
    @big_coverage_zone_width = big_coverage_zone[0]
    @big_coverage_zone_height = big_coverage_zone[1]
		@big_coverage_zone_ratio = big_coverage_zone[0].to_f / big_coverage_zone[1]
		@rotation = rotation.to_f
	end



  def near_walls?
    return false if [6,7,10,11].include? @number
    true
  end

  def nearest_wall_point
    return nil unless near_walls?
    nearest_point_coords = @coordinates.dup
    offset = 70
    nearest_point_coords.x = 0 if (@coordinates.x - offset) <= 0
    nearest_point_coords.y = 0 if (@coordinates.y - offset) <= 0
    nearest_point_coords.x = WorkZone::WIDTH if (@coordinates.x + offset) >= WorkZone::WIDTH
    nearest_point_coords.y = WorkZone::HEIGHT if (@coordinates.y + offset) >= WorkZone::HEIGHT
    nearest_point_coords
  end



  def self.number_from_point(point)
    return nil if point.nil?
    return nil if point.zero?
    ((point.x - 70.0) / 120).floor * 4    +   ((point.y - 70.0) / 120).floor   +    1
  end


	def dup
		Antenna.new(
				@number,
				[@coverage_zone_width, @coverage_zone_height],
				[@big_coverage_zone_width, @big_coverage_zone_height],
				@coordinates.dup,
				@rotation
		)
	end




  private

  def file_code_by_number
    return '' if @number.nil?
    (((@number - 1) / 4).floor + 1).to_s + "-" + ((@number - 1) % 4 + 1).to_s
  end

  def coordinates_by_number
    return Point.new(nil, nil) if @number.nil? or @number == 0
    Point.new(70 + ((@number - 1) / 4).floor * 120, 70 + ((@number - 1) % 4) * 120)
  end
end