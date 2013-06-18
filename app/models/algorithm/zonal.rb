class Algorithm::Zonal < Algorithm::Base


  def set_settings(coverage_zone_width, coverage_zone_height, metric_mode = :average, zones_mode = :ellipses)
    @metric_mode = metric_mode
    @coverage_zone_width = coverage_zone_width
    @coverage_zone_height = coverage_zone_height
    @zones_mode = zones_mode
    self
  end



  private


  def calculate_tags_output()
    tags_estimates = {}

    zones = Algorithm::Zonal::ZonesCreator.new(
        @work_zone, @zones_mode, @coverage_zone_width, @coverage_zone_height
    ).zones

    @tags.each do |tag_index, tag|
      tag_data = tag.answers[:a][@metric_mode]
      tag_estimate = make_estimate(zones, tag_data)
      tag_output = TagOutput.new(tag, tag_estimate)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end



  def make_estimate(zones, tag_data)
    antennas = tag_data.select{|k,v| k if v == 1}.keys

    found_zones = []
    antennas.length.downto(1) do |length|
      combinations = antennas.combination(length)
      combinations.each do |combination|
        found_zones.push zones[combination.to_s] if zones.keys.include? (combination.to_s)
      end
      break unless found_zones.empty?
    end

    return nil if found_zones.empty?
    Point.center_of_points found_zones
  end
end