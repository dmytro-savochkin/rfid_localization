class MiGenerator
	ELLIPSE_RATIO = 1.0
	RSS_DEGREES_SET = [1.0, 2.0]
	RANDOM_POSITION_SHIFT = 20

	attr_reader :error_generator, :rss_errors, :values, :model
	attr_accessor :responses, :antennas

	def initialize(model)
    #@antennae_accuracy = {}
    #(1..16).each{|antenna_number| @antennae_accuracy[antenna_number] = 0.75}
    #@accuracy = {:rss => 0.75, :rr => 0.65}
    #@antennae_accuracy[5] = 0.1
    #@antennae_accuracy[11] = 0.1

		@model = model

    @adaptive_limits = {:rss => -70.0, :rr => 0.1}
		@rss_errors = []
		@values = {:rss => [], :rr => []}
		@responses = {}
	end

	def set_mi_ranges
		@mi_range = create_mi_ranges if @model == :empirical
	end
	def set_error_generator
		@error_generator = MI::ErrorGenerator.new
	end
	def set_antennas(antennas)
		@antennas = antennas
	end








  def create_group(positions, reader_power, all_tags_for_sum, height_number, height_index, is_train = false)
		set_rss_model(reader_power) if @model == :empirical
		@is_train = is_train

    tags = {}
    positions.each_with_index do |position, number|
      current_position_tags_for_sum = []
      if all_tags_for_sum.present?
        current_position_tags_for_sum = all_tags_for_sum.map{|v| v[number.to_s]}
			end

			tags[number.to_s] = create(
					number.to_s, position, reader_power, current_position_tags_for_sum,
					height_number, height_index
			)
		end

    tags
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
    @rss_model = {}
    (1..16).each do |antenna_number|
      @rss_model[antenna_number] = Regression::DistancesMi.where({
          :height => 'all',
          :reader_power => reader_power,
          :antenna_number => 'all',
          :mi_type => 'rss',
          :type => 'powers=' + RSS_DEGREES_SET.map(&:to_i).join(',') + '__ellipse=' + ELLIPSE_RATIO.to_s
      }).first
    end
  end


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










  def create(tag_id, position, reader_power, tags_for_sum, height_number, height_index, rerun_if_empty = true, shift = 0.0)
		tag = TagInput.new(tag_id.to_s, 16, position, @antennas)

    if tags_for_sum.present?
      tag.fill_average_mi_values(tags_for_sum, @adaptive_limits)
    else
			@antennas.each do |antenna|
				antenna_number = antenna.number
        antenna_tag_distance = Point.distance(tag.position, antenna.coordinates)
        antenna_tag_angle = antenna.coordinates.angle_to_point(tag.position)
        rss_generating_params = [antenna_tag_distance, antenna_tag_angle, antenna_number, antenna]

				if @model == :empirical
					response_probability = calculate_response_probability(
							reader_power,
							antenna_tag_distance,
							antenna_tag_angle,
							tag_responded_on_previous_powers(
									reader_power,
									height_number,
									height_index,
									antenna_number,
									position,
									tag_id
							)
					)
					if (rand - shift) < response_probability
						@responses[height_number] ||= {}
						@responses[height_number][height_index] ||= {}
						@responses[height_number][height_index][antenna_number] ||= {}
						if @responses[height_number][height_index][antenna_number][position.to_s+tag_id.to_s].nil?
							@responses[height_number][height_index][antenna_number][position.to_s+tag_id.to_s] = reader_power
						end

						rss = generate_rss(reader_power, height_number, position, *rss_generating_params)
						if rss < @mi_range[reader_power][:rss][:min]
							rss = @mi_range[reader_power][:rss][:min]
						end
						rr = generate_rr(rss, @error_generator.class::RSS_RR_CORRELATION, reader_power)
						add_answers_to_tag(tag, antenna_number, rss, rr)
						@values[:rss].push rss
						@values[:rr].push rr
					end
				else


					#response_probability = calculate_theoretical_response_probability(
					#		reader_power,
					#		antenna,
					#		tag.position,
					#		tag_responded_on_previous_powers(
					#			reader_power,
					#			height_number,
					#			height_index,
					#			antenna_number,
					#			position,
					#			tag_id
					#		)
					#)
					#if (rand - shift) < response_probability
					#	@responses[height_number] ||= {}
					#	@responses[height_number][height_index] ||= {}
					#	@responses[height_number][height_index][antenna_number] ||= {}
					#	if @responses[height_number][height_index][antenna_number][position.to_s+tag_id.to_s].nil?
					#		@responses[height_number][height_index][antenna_number][position.to_s+tag_id.to_s] = reader_power
					#	end

						limit = MI::Rss.theoretical_range(reader_power)[:min]
						rss = generate_rss(reader_power, height_number, position, *rss_generating_params)
						if rss + shift >= limit
							rr = generate_rr(rss, @error_generator.class::RSS_RR_CORRELATION, reader_power)
							add_answers_to_tag(tag, antenna_number, rss, rr)
							@values[:rss].push rss
							@values[:rr].push rr
						end
					#end
				end

      end

      if rerun_if_empty and tag.answers_count == 0
				while tag.answers_count == 0
					puts shift.to_s + ' infinite loop?'
					tag = create(tag_id, position, reader_power, tags_for_sum, height_number, height_index, false, shift)
					shift += 0.01
				end
			end

			tag = correct_rr_values(tag.dup)
    end

    tag
	end


	def tag_responded_on_previous_powers(reader_power, height_number, height_index, antenna_number, position, tag_id)
		@responses[height_number].present? and
				@responses[height_number][height_index].present? and
				@responses[height_number][height_index][antenna_number].present? and
				@responses[height_number][height_index][antenna_number][position.to_s+tag_id.to_s].present? and
				reader_power > @responses[height_number][height_index][antenna_number][position.to_s+tag_id.to_s]
	end


	def calculate_theoretical_response_probability(reader_power, antenna, tag_position, responded_previously)
		return 1.0 if responded_previously
		distance = Point.distance(antenna.coordinates, tag_position)
		min_distance = 50.0
		return 1.0 if distance <= min_distance
		sensitivity = -54.0
		max_distance = MI::Rss.theoretical_to_distance_by_antenna_tag(sensitivity, reader_power, antenna, tag_position)
		return 0.0 if distance >= max_distance
		1.0 - (distance - min_distance) / (max_distance - min_distance)
	end

  def calculate_response_probability(reader_power, distance, angle, type)
    #minimal_distance = 35.0
    #return 1.0 if distance < minimal_distance
		return 1.0 if type == true
		#puts reader_power.to_s + ' ' + distance.to_s + ' ' + type.to_s

		ellipse_ratio = 1.5
		ellipse_min = 2.0 / (ellipse_ratio + 1)
		distance *= MI::Base.ellipse(angle, ellipse_ratio, ellipse_min)


    model = Rails.cache.fetch(
        'probabilities_distances_' + ELLIPSE_RATIO.to_s + reader_power.to_s + type.to_s,
        :expires_in => 5.day
    ) do
      Regression::ProbabilitiesDistances.where(
          :ellipse_ratio => ELLIPSE_RATIO,
          :reader_power => reader_power,
					:previous_rp_answered => type
      ).first
    end

    coeffs = JSON.parse(model.coeffs)
    probability = coeffs['const'].to_f
    coeffs['dependable'].each_with_index do |coeff, i|
      probability += coeff.to_f * distance.to_f ** (i.to_f + 1)
    end
    probability = 0.0 if probability < 0.0
    probability = 1.0 if probability > 1.0

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




	def generate_empirical_rss(reader_power, height_number, position, distance, angle, antenna_number)
		mi_model = @rss_model

		parsed_coeffs = JSON.parse(mi_model[antenna_number].mi_coeff)
		coeffs = []
		coeffs[0] = mi_model[antenna_number].const.to_f
		angle_coeff = nil
		angle_coeff = mi_model[antenna_number].angle_coeff.to_f if mi_model[antenna_number].angle_coeff != nil
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

		#regression_rss = MI::Rss.regression_root(1.0,0.0,0.0,[-71.0, -60.0],-65.5,coeffs,nil)

		error = @error_generator.get_rss_error(position, reader_power, antenna_number, height_number)
		@rss_errors << error
		regression_rss + error
	end

	def generate_theoretical_rss(reader_power, height_number, position, distance, angle, antenna_number, antenna)
		ideal_rss = MI::Rss.theoretical_rss(antenna, position, height_number, reader_power)
		error = @error_generator.get_rss_error(position, reader_power, antenna_number, height_number)
		@rss_errors << error
		if @is_train == :train
			ideal_rss
		else
			ideal_rss + error
		end
	end



	def generate_rss(reader_power, height_number, position, distance, angle, antenna_number, antenna)
		if @model == :theoretical
			generate_theoretical_rss(reader_power, height_number, position, distance, angle, antenna_number, antenna)
		elsif @model == :empirical
			generate_empirical_rss(reader_power, height_number, position, distance, angle, antenna_number)
		else
			raise Exception.new("Wrong model " + @model.to_s)
		end
  end




  def generate_rr(rss, correlation, reader_power)
		range = (@model == :theoretical ? MI::Rss.theoretical_range(reader_power) : nil)
    normalized_rss = MI::Rss.normalize_value(rss, reader_power, range)
    #normalized_rss2 = MI::Rss.normalize_value(rss2, reader_power)
    #random = Rubystats::NormalDistribution.new(0.5, 0.15).rng.to_f
    #random = 1.0 if random > 1.0
    #random = 0.0 if random < 0.0
    rr = correlation * normalized_rss + Math.sqrt(1 - correlation ** 2) * rand
		rr = 1.0 if rr > 1.0
    rr = 0.0 if rr < 0.0
    rr
  end




	def correct_rr_values(tag)
		antennas = tag.answers[:rss][:average].sort_by{|k,v|v}.map(&:first)
		#antennas = tag.answers[:rss][:average].map(&:first)
		#new_rss_values = Hash[tag.answers[:rss][:average].sort_by{|k,v|v}]
		tag.answers[:rr][:average] = Hash[antennas.zip tag.answers[:rr][:average].values.sort]
		tag


		#puts rss_values.to_s
		#puts new_rss_values.to_s
		#puts antennas.to_s
		#puts rr_values.to_s
		#puts Hash[rr_values.sort_by{|k,v| new_rss_values.keys.index k}].to_s
		#puts new_rr_values.to_s
		#puts '-'
	end



  def random_position
    shift = RANDOM_POSITION_SHIFT
    Point.new(rand((shift..WorkZone::WIDTH-shift)), rand((shift..WorkZone::HEIGHT-shift)))
  end
end