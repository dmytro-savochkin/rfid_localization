class Regression::CreatorProbabilitiesDistances

  def initialize
  end


  def calculate_response_probabilities
    ellipse_ratios = [1.0, 1.5]
    reader_powers = (20..30).to_a
    responses = calculate_responses(ellipse_ratios, reader_powers)
		probabilities = calculate_probabilities(ellipse_ratios, reader_powers, responses)

		puts Hash[probabilities[21][1.0][false].sort_by{|k,v|k.to_i}].to_yaml

		models = regression(ellipse_ratios, reader_powers, probabilities)
    correlation = calculate_correlation(ellipse_ratios, reader_powers, models, probabilities)
    graphs = make_graphs(ellipse_ratios, reader_powers, models)
    save_models_to_db(ellipse_ratios, reader_powers, models)

    [probabilities, models, correlation, graphs]
  end




  private

  def calculate_responses(ellipse_ratios, reader_powers)
    responses = {}


		responses_by_tags = {}

    reader_powers.each do |rp|
			responses_by_tags[rp] ||= {}
			responses[rp] ||= {}
			ellipse_ratios.each do |er|
				responses[rp][er] ||= {}
				responses[rp][er][true] ||= {}
				responses[rp][er][false] ||= {}
				responses[rp][er]['null'] ||= {}
				responses_by_tags[rp][er] ||= {}
				MI::Base::HEIGHTS.each do |height|
					responses_by_tags[rp][er][height] ||= {}
					responded_tags = MI::Base.parse_specific_tags_data(height, rp)
					TagInput.tag_ids.each do |tag_id|
						responses_by_tags[rp][er][height][tag_id] ||= {}
						tag = TagInput.new(tag_id)

						(1..16).each do |antenna_number|
							antenna = Antenna.new(antenna_number)
							distance = antenna.coordinates.distance_to_point(tag.position)
							angle = antenna.coordinates.angle_to_point(tag.position)
							distance_modified = distance * MI::Base.ellipse(angle, er)
							distance_string = distance_modified.round.to_s

							previous_answered = responses_by_tags[rp-1][er][height][tag_id][antenna_number] rescue false

							[previous_answered, 'null'].each do |type|
								responses[rp][er][type][distance_string] ||= {
										:responses => 0,
										:total => 0
								}
								responses[rp][er][type][distance_string][:total] += 1
								if responded_tags[tag_id].present? and responded_tags[tag_id].answers[:rss][:average][antenna_number].present?
									responses_by_tags[rp][er][height][tag_id][antenna_number] = true
									responses[rp][er][type][distance_string][:responses] += 1
								else
									responses_by_tags[rp][er][height][tag_id][antenna_number] = false
								end
							end
						end
					end
				end
			end
		end

    responses
  end

  def calculate_probabilities(ellipse_ratios, reader_powers, responses)
    probabilities = {}

    reader_powers.each do |rp|
      probabilities[rp] ||= {}
      ellipse_ratios.each do |er|
        probabilities[rp][er] ||= {}
        [true, false, 'null'].each do |previous_rp_answered|
					probabilities[rp][er][previous_rp_answered] ||= {}
					responses[rp][er][previous_rp_answered].each do |distance_string, data|
						probabilities[rp][er][previous_rp_answered][distance_string] =
								data[:responses].to_f / data[:total].to_f
					end
				end
      end
    end

    probabilities
  end





  def regression(ellipse_ratios, reader_powers, probability_data)
    models = {}

    reader_powers.each do |rp|
      models[rp] ||= {}
      ellipse_ratios.each do |er|
				models[rp][er] ||= {}
				[true, false, 'null'].each do |previous_rp_answered|
					if previous_rp_answered == 'null'
						max_degree = 4
						#max_degree = 5 if rp <= 21
					else
						#max_degree = 5 if rp == 20
						#max_degree = 4 if rp >= 21
						max_degree = 4 if rp >= 20
						max_degree = 3 if rp == 23
						max_degree = 3 if rp >= 26
					end

					next if rp == 20 and previous_rp_answered == true
					data = Hash[probability_data[rp][er][previous_rp_answered].sort_by{|k,v| k.to_i}]
					distances = data.keys.map{|v|v.to_f}
					probabilities = data.values.map{|v|v.to_f}

					cut_index = nil
					distances.each_with_index do |distance, i|
						if probabilities[i] == 0.0 and probabilities[i-1] == 0.0
							cut_index = i
							break
						end
					end

					if cut_index.present?
						probabilities = probabilities[0...cut_index]
						distances = distances[0...cut_index]
					end

					regression_data_set = {
							'y' => probabilities.to_vector(:scale)
					}

					(1..max_degree).each do |degree|
						regression_data_set['x_' + degree.to_s] = distances.map{|p| p ** (degree.to_f)}.to_vector(:scale)
					end

					#puts rp.to_s + ' ' + previous_rp_answered.to_s
					#puts regression_data_set.to_s

					regression_data_set = regression_data_set.to_dataset
					models[rp][er][previous_rp_answered] =
							Statsample::Regression.multiple(regression_data_set, 'y', {:digits => 10})
				end
      end
    end

    models
  end




  def calculate_correlation(ellipse_ratios, reader_powers, models, probabilities)
    correlation = {}

    reader_powers.each do |rp|
      correlation[rp] ||= {}
      ellipse_ratios.each do |er|
				correlation[rp][er] ||= {}
				[true, false, 'null'].each do |previous_rp_answered|
					next if rp == 20 and previous_rp_answered == true
					calc_probabilities = []
					probabilities[rp][er][previous_rp_answered].keys.each do |distance|
						calc_probabilities.push(calculate_probability_by_model(models[rp][er][previous_rp_answered], distance))
					end

					correlation[rp][er][previous_rp_answered] =
							Math.correlation(probabilities[rp][er][previous_rp_answered].values, calc_probabilities)
				end
			end
    end

    correlation
  end

  def make_graphs(ellipse_ratios, reader_powers, models)
    graphs = {}

    reader_powers.each do |rp|
      graphs[rp] ||= {}
      ellipse_ratios.each do |er|
        graphs[rp][er] ||= {}
				[true, false, 'null'].each do |previous_rp_answered|
					next if rp == 20 and previous_rp_answered == true
					graphs[rp][er][previous_rp_answered] = []
					model = models[rp][er][previous_rp_answered]
					(0..700).step(5).each do |distance|
						probability = calculate_probability_by_model(model, distance)
						graphs[rp][er][previous_rp_answered].push([distance.to_f, probability])
					end
				end
      end
    end

    graphs
  end



  def save_models_to_db(ellipse_ratios, reader_powers, models)
    reader_powers.each do |rp|
      ellipse_ratios.each do |er|
				[true, false, 'null'].each do |previous_rp_answered|
					next if rp == 20 and previous_rp_answered == true
					if Regression::ProbabilitiesDistances.where(
							:ellipse_ratio => er,
							:reader_power => rp,
							:previous_rp_answered => previous_rp_answered
					).count == 0
						data = {
								:const => models[rp][er][previous_rp_answered].constant.to_f,
								:dependable => models[rp][er][previous_rp_answered].coeffs.values
						}.to_json

						model = Regression::ProbabilitiesDistances.new({
								:ellipse_ratio => er,
								:reader_power => rp,
								:previous_rp_answered => previous_rp_answered,
								:coeffs => data
						})
						model.save
					end
				end
      end
    end
  end





  def calculate_probability_by_model(model, distance)
    probability = model.constant.to_f
    model.coeffs.values.each_with_index do |coeff, i|
      probability += coeff.to_f * distance.to_f ** (i.to_f + 1)
    end
    probability = 0.0 if probability < 0.0
    probability = 1.0 if probability > 1.0
    probability
  end
end