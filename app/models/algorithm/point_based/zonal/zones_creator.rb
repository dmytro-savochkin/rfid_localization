class Algorithm::PointBased::Zonal::ZonesCreator
  attr_reader :zones

  def initialize(work_zone, mode, reader_power, step = 5)
    @work_zone = work_zone
    @mode = mode
    @step = step
    @reader_power = reader_power
    @zones = create_zones
  end



  def create_zones
    zones = {}
    zones_points = {}

    (0..@work_zone.width).step(@step) do |x|
      (0..@work_zone.height).step(@step) do |y|
        point = Point.new(x, y)

        active_antennas = []
        1.upto(16) do |antenna_number|
          antenna = Antenna.new(antenna_number, Zone::POWERS_TO_SIZES[@reader_power])
          active_antennas.push antenna_number if point_in_antenna_coverage?(point, antenna)
        end

        zones_points[active_antennas.to_s] ||= []
        zones_points[active_antennas.to_s].push point
      end
    end

    zones_points.each do |antenna_combination, points|
      zones[antenna_combination] = Point.center_of_points points
    end

    zones
  end




  def point_in_antenna_coverage?(point, antenna)
    return MeasurementInformation::A.point_in_ellipse?(point, antenna) if @mode == :ellipses
    return MeasurementInformation::A.point_in_rectangle?(point, antenna) if @mode == :rectangles
    false
  end


end