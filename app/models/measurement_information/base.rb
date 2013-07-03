class MeasurementInformation::Base
  READER_POWERS = (19..30)
  HEIGHTS = [41, 69, 98, 116]
  FREQUENCY = 'multi'

  MINIMAL_POSSIBLE_MI_VALUE = 0.0

  class << self
    def distances_hash(mi_hash, reader_power)
      distances_hash = {}
      mi_hash.each do |antenna, mi|
        mi_object = self.new(mi, reader_power)
        distances_hash[antenna] = mi_object.to_distance if mi > self::MINIMAL_POSSIBLE_MI_VALUE
      end
      distances_hash
    end




    def parse
      measurement_information = {}

      READER_POWERS.each do |reader_power|
        measurement_information[reader_power] ||= {}
        HEIGHTS.each do |height|
          work_zone_cache_name = "work_zone_" + reader_power.to_s
          tags_cache_name = "parse_data_" + height.to_s + reader_power.to_s + FREQUENCY.to_s
          measurement_information[reader_power][height] = {
              :work_zone => Rails.cache.fetch(work_zone_cache_name, :expires_in => 1.day) do
                WorkZone.new(reader_power)
              end,
              :tags => Rails.cache.fetch(tags_cache_name, :expires_in => 1.day) do
                Parser.parse(height, reader_power, FREQUENCY)
              end,
              :reader_power => reader_power
          }
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
          tags_mi = measurement_information[reader_power][height][:tags]
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