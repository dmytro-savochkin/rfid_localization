class TagOutput
  attr_accessor :estimate, :error, :id, :zone_estimate, :zone_error

  def initialize(tag, estimate, zone = nil)
    return nil if tag.nil?
    @id = tag.id.to_s
    @estimate = estimate
    @error = Point.distance(estimate, tag.position)
    @zone_estimate = zone
    if zone.present?
      @zone_error = zone.class.error_between_zones(zone, tag.nearest_antenna)
    end

  end

end
