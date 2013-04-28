class Algorithm::Zonal < Algorithm::Base


  def set_settings(coverage_zone_width, coverage_zone_height, metric_mode = :average, zones_mode = :ellipses)
    @metric_mode = metric_mode
    @coverage_zone_width = coverage_zone_width
    @coverage_zone_height = coverage_zone_height
    @zones_mode = zones_mode
    self
  end



  private


  def calc_errors_for_tags()
    zones = Algorithm::Zonal::ZonesCreator.new(@work_zone, @zones_mode, @coverage_zone_width, @coverage_zone_height).zones

    @tags.each do |tag_index, data|
      tag = @tags[tag_index]
      tag_data = tag.answers[:a][@metric_mode]
      tag.estimate = make_estimate zones, tag_data

      puts tag.id
      puts tag.estimate.to_yaml

      tag.error = Point.distance(tag.estimate, tag.position)
    end
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

    Point.center_of_points found_zones
  end
end