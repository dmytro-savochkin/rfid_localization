class Algorithm::PointBased::Zonal::ZonesCreator
  attr_reader :zones

  def initialize(work_zone, mode, reader_power, step = 5)
    @work_zone = work_zone
    @mode = mode
    @step = step.to_i
    @reader_power = reader_power
  end







  def create_coverage_zones
    zones = {}

    (0..@work_zone.width).step(@step) do |x|
      (0..@work_zone.height).step(@step) do |y|
        point = Point.new(x, y)

        1.upto(16) do |antenna_number|
          antenna = Antenna.new(antenna_number, Zone::POWERS_TO_SIZES[@reader_power])
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

        active_antennas = []
        1.upto(16) do |antenna_number|
          antenna = Antenna.new(antenna_number, Zone::POWERS_TO_SIZES[@reader_power])
          active_antennas.push antenna_number if point_in_antenna_coverage?(point, antenna)
        end

        zones[active_antennas.to_s] ||= []
        zones[active_antennas.to_s].push point
      end
    end

    zones
  end



  def elementary_zones_centers
    zones = create_elementary_zones

    zones.each do |antenna_combination, points|
      zones[antenna_combination] = Point.center_of_points points
    end

    zones
  end



  def point_in_antenna_coverage?(point, antenna)
    return MI::A.point_in_ellipse?(point, antenna) if @mode == :ellipses
    return MI::A.point_in_rectangle?(point, antenna) if @mode == :rectangles
    false
  end


end