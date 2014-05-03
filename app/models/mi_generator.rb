class MiGenerator
	ELLIPSE_RATIO = 1.0

	attr_accessor :separate_rss_biases, :separate_rss_stddevs

	def initialize
    #@antennae_accuracy = {}
    #(1..16).each{|antenna_number| @antennae_accuracy[antenna_number] = 0.75}
    #@accuracy = {:rss => 0.75, :rr => 0.65}
    #@antennae_accuracy[5] = 0.1
    #@antennae_accuracy[11] = 0.1

    @adaptive_limits = {:rss => -70.0, :rr => 0.1}
    @mi_range = create_mi_ranges

		@error_generator = MI::ErrorGenerator.new
  end














  def create_group(positions, reader_power, all_tags_for_sum, height_number)
    set_rss_model(reader_power)
    set_rr_model(reader_power)

    tags = {}
    positions.each_with_index do |position, number|
      current_position_tags_for_sum = []
      if all_tags_for_sum.present?
        current_position_tags_for_sum = all_tags_for_sum.map{|v| v[number.to_s]}
			end

			tags[number.to_s] = create(
					number.to_s,
					position,
					reader_power,
					current_position_tags_for_sum
			)
    end
    tags
  end




  def create_grid_positions(count, shift)
    start_point = Point.new(shift, shift)
    end_point = Point.new(WorkZone::WIDTH.to_f - shift, WorkZone::HEIGHT.to_f - shift)

    count_in_row = Math.sqrt(count.to_f).floor
    step = (end_point.x - start_point.x) / (count_in_row - 1)
    step = 0.0 if count_in_row <= 1

    positions = []

    count_in_row.times do |x|
      count_in_row.times do |y|
        positions.push( Point.new(start_point.x + x * step, start_point.y + y * step) )
      end
    end

    positions
  end


  def create_random_positions(count)
    positions = []
    count.times do
      positions.push random_position
    end
    positions
  end







  private

  def set_rss_model(reader_power)
    #reader_power = 24 if reader_power == :sum or reader_power > 24
    @rss_model = {}
    (1..16).each do |antenna_number|
      @rss_model[antenna_number] = Regression::DistancesMi.where({
          :height => 'all',
          :reader_power => reader_power,
          :antenna_number => 'all',
          :mi_type => 'rss',
          :type => 'powers=1,2__ellipse=1.0'
      }).first
    end
  end

  def set_rr_model(reader_power)
    reader_power = 24 if reader_power == :sum or reader_power > 24
    @rr_model = {}
    (1..16).each do |antenna_number|
      @rr_model[antenna_number] = Regression::DistancesMi.where({
          :height => 'all',
          :reader_power => reader_power,
          :antenna_number => 'all',
          :mi_type => 'rr',
          :type => 'powers=1__ellipse=1.0'
      }).first
    end
  end



  #def create_rss_limits()
  #  rss_limit = {}
  #  (20..30).each do |reader_power|
  #    rss_limit[reader_power] = @mi_range[reader_power][:rss][:min]
  #    #rss_limit[reader_power] = -73.0
  #    #rss_limit[reader_power] = -71.0 if reader_power == 20
  #    #rss_limit[reader_power] = -72.0 if reader_power == 21 or reader_power == 22
  #  end
  #  rss_limit
  #end

  def create_mi_ranges
    mi_range = {}
    (20..30).each do |reader_power|
      mi_range[reader_power] ||= {}
      [:rss].each do |mi_type|
        boundary = Regression::MiBoundary.where(:type => mi_type, :reader_power => reader_power).first
        mi_range[reader_power][mi_type] = {
            :min => boundary.min.to_f, :max => boundary.max.to_f,
            :center => boundary.max.to_f - (boundary.max.to_f - boundary.min.to_f)/2
        }
      end
    end
    mi_range
  end










  def create(tag_id, position, reader_power, tags_for_sum)
    tag = TagInput.new(tag_id.to_s, 16, position)

    if tags_for_sum.present?

      tag.fill_average_mi_values(tags_for_sum, @adaptive_limits)

    else

      best_antenna_rss_pair = [nil, -1.0/0.0]
      (1..16).each do |antenna_number|
        antenna = Antenna.new(antenna_number)

        antenna_tag_distance = Point.distance(tag.position, antenna.coordinates)
        antenna_tag_angle = antenna.coordinates.angle_to_point(tag.position)

        rss_generating_params = [
            antenna_tag_distance,
            antenna_tag_angle,
            antenna_number
        ]

        modified_distance = antenna_tag_distance * MI::Base.ellipse(antenna_tag_angle, ELLIPSE_RATIO)
        response_probability = calculate_response_probability(reader_power, modified_distance)

				random_value = @error_generator.get_response_probability_number(position, reader_power, antenna_number)
				if random_value < response_probability
          rss = generate_rss(reader_power, position, *rss_generating_params)
          best_antenna_rss_pair = [antenna_number, rss] if rss > best_antenna_rss_pair[1]
          if rss > @mi_range[reader_power][:rss][:min]
            rr = generate_rr(rss, @error_generator.class::RSS_RR_CORRELATION)
            add_answers_to_tag(tag, antenna_number, rss, rr)
          end
        end
      end

      if tag.answers_count == 0
        tag = create(tag_id, position, reader_power, tags_for_sum)
      end
    end

    tag
  end


  def calculate_response_probability(reader_power, distance)
    minimal_distance = 50.0
    return 1.0 if distance < minimal_distance

    model = Rails.cache.fetch(
        'probabilities_distances_' + ELLIPSE_RATIO.to_s + reader_power.to_s,
        :expires_in => 5.day
    ) do
      Regression::ProbabilitiesDistances.where(
          :ellipse_ratio => ELLIPSE_RATIO,
          :reader_power => reader_power
      ).first
    end

    coeffs = JSON.parse(model.coeffs)
    probability = coeffs['const'].to_f
    coeffs['dependable'].each_with_index do |coeff, i|
      probability += coeff.to_f * distance.to_f ** (i.to_f + 1)
    end
    probability = 0.0 if probability < 0.0

    probability
  end







  def add_answers_to_tag(tag, antenna_number, rss, rr)
    tag.answers_count += 1
    tag.answers[:a][:average][antenna_number] = 1
    tag.answers[:a][:adaptive][antenna_number] = 1 if rss > @adaptive_limits[:rss]
    tag.answers[:rss][:average][antenna_number] = rss
    tag.answers[:rss][:adaptive][antenna_number] = rss if rr > @adaptive_limits[:rr]
    tag.answers[:rr][:average][antenna_number] = rr
  end


  #def generate_distance_error(antenna_accuracy)
  #  # нужно здесь исключить случай, когда генерируется отрицательная дистанция
  #  distance_error_std_dev =
  #      Antenna::ERROR_LIMITS[:rss] -
  #      Antenna::ERROR_LIMITS[:rss] * antenna_accuracy
  #  #Math.rayleigh_value(distance_error_expected_value) * [1.0, -1.0].sample
  #  #Rubystats::NormalDistribution.new(distance_error_ev, @distance_std_dev).rng.to_f
  #  Rubystats::NormalDistribution.new(0, distance_error_std_dev).rng.to_f
  #end



  def generate_rss(reader_power, position, distance, angle, antenna_number)
    mi_model = @rss_model

    parsed_coeffs = JSON.parse(mi_model[antenna_number].mi_coeff)
    coeffs = []
    coeffs[0] = mi_model[antenna_number].const.to_f
    angle_coeff = nil
    angle_coeff = mi_model[antenna_number].angle_coeff if mi_model[antenna_number].angle_coeff != nil
    parsed_coeffs.each do |k, mi_coeff|
      unless mi_coeff.nil?
        coeffs.push mi_coeff.to_f
      end
    end

    regression_rss = MI::Rss.regression_root(
				ELLIPSE_RATIO,
        angle,
        distance,
        [@mi_range[reader_power][:rss][:min], @mi_range[reader_power][:rss][:max]],
        @mi_range[reader_power][:rss][:center],
        coeffs,
        angle_coeff
    )

		regression_rss + @error_generator.get_rss_error(position, reader_power, antenna_number)
  end









  def generate_rr(rss, correlation)
    normalized_rss = normalize_rss(rss)
    random = Rubystats::NormalDistribution.new(0.5, 0.15).rng.to_f
    random = 1.0 if random > 1.0
    random = 0.0 if random < 0.0
    rr = correlation * normalized_rss + Math.sqrt(1 - correlation ** 2) * random
    rr = 1.0 if rr > 1.0
    rr = 0.0 if rr < 0.0
    rr
  end
	def normalize_rss(rss)
		max = -75.0
		diff = 20
		return 1.0 if rss > -55.0
		[(rss - max).abs / diff, 1.0].min
	end








  def random_position
    shift = 10
    Point.new(rand((shift..WorkZone::WIDTH-shift)), rand((shift..WorkZone::HEIGHT-shift)))
  end
end