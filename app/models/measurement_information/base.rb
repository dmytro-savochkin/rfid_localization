class MeasurementInformation::Base
  READER_POWERS = (19..30).to_a.concat([:sum])
  HEIGHTS = [41, 69, 98, 116]
  FREQUENCY = 'multi'

  MINIMAL_POSSIBLE_MI_VALUE = 0.0

  class << self
    def class_by_mi_type(name)
      ('MeasurementInformation::' + name.to_s.capitalize).constantize
    end


    def angles_hash(mi_hash, point)
      angles_hash = {}
      mi_hash.each_key do |antenna_number|
        antenna = Antenna.new(antenna_number)
        angles_hash[antenna_number] = antenna.coordinates.angle_to_point(point)
      end
      angles_hash
    end


    def distances_hash(mi_hash, angles_hash, reader_power, type)
      height = MeasurementInformation::Base::HEIGHTS.first
      distances_hash = {}
      mi_hash.zip(angles_hash).each do |antenna_mi, antenna_angle|
        antenna = antenna_mi[0]
        mi = antenna_mi[1]
        angle = antenna_angle[1]
        if mi > self::MINIMAL_POSSIBLE_MI_VALUE
          distances_hash[antenna] = self.to_distance(mi, angle, antenna, height, reader_power) if type == 'new'
          distances_hash[antenna] = self.to_distance_old(mi) if type == 'old'
        end
      end
      distances_hash
    end






    def tags_cache_name(height, reader_power, shrinkage)
      "parse_data_" + height.to_s + reader_power.to_s + FREQUENCY.to_s + shrinkage.to_s
    end

    def parse_specific_tags_data(height, reader_power, shrinkage = false)
      Rails.cache.fetch(tags_cache_name(height, reader_power, shrinkage), :expires_in => 1.day) do
        Parser.parse(height, reader_power, FREQUENCY)
      end
    end

    def parse
      measurement_information = {}

      READER_POWERS.each do |reader_power|
        measurement_information[reader_power] = {}
        measurement_information[reader_power][:reader_power] = reader_power

        work_zone_cache_name = "work_zone_" + reader_power.to_s
        measurement_information[reader_power][:work_zone] = Rails.cache.fetch(work_zone_cache_name, :expires_in => 1.day) do
          WorkZone.new(reader_power)
        end

        measurement_information[reader_power][:tags] = {}
        HEIGHTS.each do |height|
          measurement_information[reader_power][:tags][height] = parse_specific_tags_data(
              height,
              reader_power,
              false
          )
        end
      end

      measurement_information
    end


    def calc_rss_rr_correlation(measurement_information)
      correlation = {}

      READER_POWERS.each do |reader_power|
        correlation[reader_power] ||= {}
        HEIGHTS.each do |height|
          correlation[reader_power][height] ||= {}
          rss_rr_by_antenna = {}
          tags_mi = measurement_information[reader_power][height][:tags_test_input]
          tags_mi.each do |tag_name, tag|
            answers = tag.answers
            answers[:rss][:average].each do |antenna, rss|
              rr = answers[:rr][:average][antenna]
              rss_rr_by_antenna[antenna] ||= []
              rss_rr_by_antenna[antenna].push([rss, rr])
            end
          end

          1.upto(16) do |antenna|
            correlation[reader_power][height][antenna] = calc_correlation(rss_rr_by_antenna[antenna])
          end
        end
      end

      correlation
    end


    private

    def calc_correlation(array)
      x_avg = array.map{|v|v.first}.inject(&:+) / array.length
      y_avg = array.map{|v|v.last}.inject(&:+) / array.length

      nominator = 0.0
      denominator_first_part = 0.0
      denominator_second_part = 0.0
      array.each do |pair|
        x = pair.first
        y = pair.last
        nominator += (x - x_avg) * (y - y_avg)
        denominator_first_part += (x - x_avg) ** 2
        denominator_second_part += (y - y_avg) ** 2
      end
      denominator = Math.sqrt(denominator_first_part * denominator_second_part)
      nominator / denominator
    end

  end
end