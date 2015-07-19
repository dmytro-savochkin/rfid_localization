class Algorithm::PointBased::Zonal::ZonesCreator
  attr_reader :zones

  def initialize(work_zone, mode, step = 5)
    @work_zone = work_zone
    @mode = mode
    @step = step.to_i
		@mi_a_c_code = MI::A::CCode.new
  end







  def create_coverage_zones
    zones = {}

    (0..@work_zone.width).step(@step) do |x|
      (0..@work_zone.height).step(@step) do |y|
        point = Point.new(x, y)

				@work_zone.antennae.each do |antenna_number, antenna|
					if point_in_antenna_coverage?(point, antenna)
						zones[antenna_number] ||= Set.new
						zones[antenna_number].add [x, y]
					end
				end
      end
    end

    zones
  end






  def create_elementary_zones
    zones = {}

    (0..@work_zone.width).step(@step) do |x|
      (0..@work_zone.height).step(@step) do |y|
        point = Point.new(x, y)
				next if @work_zone.inside_obstructions?(point) or @work_zone.inside_passages?(point)

				# делать комбинации зон с учетом больших и маленьких кругов
				# (или точнее с учетом среднего между ними)

				active_antennas = []
				@work_zone.antennae.each do |antenna_number, antenna|
					blocked = @work_zone.points_blocked_by_obstructions?(point, antenna.coordinates)
					if not blocked and point_in_antenna_coverage?(point, antenna)
						active_antennas.push antenna_number
					end
        end

        zones[active_antennas.to_s] ||= []
        zones[active_antennas.to_s].push point
      end
    end

    zones
  end



  def elementary_zones_centers(zones)
		centers = {}
    zones.each do |antenna_combination, points|
      centers[antenna_combination] = Point.center_of_points points
    end
    centers
  end



  def point_in_antenna_coverage?(point, antenna, coverage_type = :min)
		if coverage_type == :max
			coverage_size = [antenna.big_coverage_zone_width, antenna.big_coverage_zone_height]
		else
			# for deployment
			coverage_size = [antenna.coverage_zone_width, antenna.coverage_zone_height]
			# for localization
			#coverage_size = Zone::POWERS_TO_SIZES[@work_zone.reader_power].map{|v|v*2}
		end
    return MI::A.point_in_ellipse?(point, antenna, coverage_size, @mi_a_c_code) if @mode == :ellipses
    return MI::A.point_in_rectangle?(point, antenna) if @mode == :rectangles
    false
  end


end