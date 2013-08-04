class Algorithm::PointBased::Zonal < Algorithm::PointBased


  def set_settings(metric_mode = :average, zones_mode = :ellipses)
    @metric_mode = metric_mode
    @zones_mode = zones_mode
    self
  end



  private


  def calc_tags_output
    tags_estimates = {}

    zones = Algorithm::PointBased::Zonal::ZonesCreator.new(
        @work_zone, @zones_mode, @reader_power
    ).zones


    n = 1
    Benchmark.bm(7) do |x|
      x.report('zonal') do
        n.times do

          @tags_test_input.each do |tag_index, tag|
            tag_data = tag.answers[:a][@metric_mode]

            if @metric_mode == :adaptive
              tag_data = tag.answers[:a][:average] if tag_data.select{|antenna,answer|answer == 1}.empty?
            end

            tag_estimate = make_estimate(zones, tag_data)
            tag_output = TagOutput.new(tag, tag_estimate)
            tags_estimates[tag_index] = tag_output
          end

        end
      end
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

    return Point.new(0,0) if found_zones.empty?
    Point.center_of_points found_zones
  end
end