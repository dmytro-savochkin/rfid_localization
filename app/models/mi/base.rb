class MI::Base
  READER_POWERS = (19..30).to_a.concat([:sum])
  HEIGHTS = [41, 69, 98, 116]
  FREQUENCY = 'multi'

  MINIMAL_POSSIBLE_MI_VALUE = 0.0

  class << self
    def class_by_mi_type(name)
      ('MI::' + name.to_s.capitalize).constantize
    end


    def ellipse(fi, ellipse_ratio = 2.0)
      rotation = Math::PI / 4
      b = 1.0
      a = b * ellipse_ratio
      #b = 0.85
      #a = 1.275
      numerator = Math.sqrt(2.0) * a * b
      denominator = Math.sqrt(a**2 + b**2 + (b**2 - a**2) * Math.cos(2 * fi - 2 * rotation))
      numerator / denominator
    end


    def angles_hash(mi_hash, point)
      angles_hash = {}
      mi_hash.each_key do |antenna_number|
        antenna = Antenna.new(antenna_number)
        angles_hash[antenna_number] = antenna.coordinates.angle_to_point(point)
      end
      angles_hash
    end


    def distances_hash(mi_hash, angles_hash, reader_power, type, height_index, antenna_type, model_type, ellipse_ratio = 2.0)
      height = MI::Base::HEIGHTS[height_index]
      distances_hash = {}
      mi_hash.zip(angles_hash).each do |antenna_mi, antenna_angle|
        antenna = antenna_mi[0]
        mi = antenna_mi[1]
        angle = antenna_angle[1]
        if mi > self::MINIMAL_POSSIBLE_MI_VALUE
          distances_hash[antenna] = self.to_distance(mi, angle, antenna, antenna_type, height, reader_power, model_type, ellipse_ratio) if type == 'new'
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
          rss_by_antenna = {}
          rr_by_antenna = {}
          tags_mi = measurement_information[reader_power][height][:tags_test_input]
          tags_mi.each do |tag_name, tag|
            answers = tag.answers
            answers[:rss][:average].each do |antenna, rss|
              rr = answers[:rr][:average][antenna]
              rss_by_antenna[antenna] ||= []
              rr_by_antenna[antenna] ||= []
              rss_by_antenna[antenna].push rss
              rr_by_antenna[antenna].push rr
            end
          end

          1.upto(16) do |antenna|
            correlation[reader_power][height][antenna] =
                Math.correlation(rss_by_antenna[antenna], rr_by_antenna[antenna])
          end
        end
      end

      correlation
    end


    def normalize_value(datum)
      datum
    end



    def regression_root(ellipse_ratio, angle, distance, mi_range, mi_range_center, coeffs, angle_coeff)
      modified_coeffs = coeffs.dup
      modified_coeffs[0] = modified_coeffs[0] - distance
      if angle_coeff.present?
        modified_coeffs[1] += angle_coeff * MI::Base.ellipse(angle, ellipse_ratio)
      end

      all_possible_mi_values = Math.real_roots(modified_coeffs.reverse)
      strictly_possible_mi_values = self.filter_possible_values(all_possible_mi_values, mi_range)
      if strictly_possible_mi_values.empty?
        weekly_possible_mi_values = self.filter_possible_values(all_possible_mi_values)
        mi_values = [weekly_possible_mi_values.sort_by{|v| (v - mi_range_center).abs}.first]
      else
        mi_values = strictly_possible_mi_values
      end

      if mi_values.length > 1
        mi_values.mean
      else
        mi_values.first
      end
    end

    def filter_possible_values(array, range = self.week_range_for_regression)
      raise Exception.new('min and max values order is wrong') if range[0] > range[1]
      array.select{|mi| mi > range[0] and mi < range[1]}
    end
  end
end