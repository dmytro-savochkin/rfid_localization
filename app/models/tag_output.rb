class TagOutput
  attr_accessor :estimate, :error, :id, :zone_estimate, :zone_error_code, :zone_error

  def initialize(tag, estimate, zone = nil)
    return nil if tag.nil?
    @id = tag.id.to_s
    @estimate = estimate
    @error = Point.distance(estimate, tag.position)
    @zone_estimate = zone
    if zone.present?
      calc_zones_error(zone, tag)
    end
  end


  def nil?
    return true if @id.nil?
    false
  end

  private


  def calc_zones_error(zone, tag)
    if zone.coordinates.nil?
      @zone_error = 1.0
      @zone_error_code = :not_found
    elsif zone.coordinates.to_s == tag.nearest_antenna.coordinates.to_s
      @zone_error = 0.0
      @zone_error_code = :ok
    else
      @zone_error = 1.0
      @zone_error_code = :error
    end
  end




end
