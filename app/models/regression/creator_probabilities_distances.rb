class Regression::CreatorProbabilitiesDistances

  def initialize
  end


  def calculate_response_probabilities
    ellipse_ratios = [1.0, 1.5]
    reader_powers = (20..30).to_a
    responses = calculate_responses(ellipse_ratios, reader_powers)
    probabilities = calculate_probabilities(ellipse_ratios, reader_powers, responses)
    models = regression(ellipse_ratios, reader_powers, probabilities)
    correlation = calculate_correlation(ellipse_ratios, reader_powers, models, probabilities)
    graphs = make_graphs(ellipse_ratios, reader_powers, models)
    save_models_to_db(ellipse_ratios, reader_powers, models)

    [probabilities, models, correlation, graphs]
  end




  private

  def calculate_responses(ellipse_ratios, reader_powers)
    responses = {}

    reader_powers.each do |rp|
      responses[rp] ||= {}
      ellipse_ratios.each do |er|
        responses[rp][er] ||= {}
        MI::Base::HEIGHTS.each do |height|
          responded_tags = MI::Base.parse_specific_tags_data(height, rp)
          TagInput.tag_ids.each do |tag_id|
            tag = TagInput.new(tag_id)

            (1..16).each do |antenna_number|
              antenna = Antenna.new(antenna_number)
              distance = antenna.coordinates.distance_to_point(tag.position)
              angle = antenna.coordinates.angle_to_point(tag.position)
              distance_modified = distance * MI::Base.ellipse(angle, er)
              distance_string = distance_modified.round.to_s

              responses[rp][er][distance_string] ||= {
                  :responses => 0,
                  :total => 0
              }
              responses[rp][er][distance_string][:total] += 1
              if responded_tags[tag_id].present? and responded_tags[tag_id].answers[:rss][:average][antenna_number].present?
                responses[rp][er][distance_string][:responses] += 1
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
        responses[rp][er].each do |distance_string, data|
          probabilities[rp][er][distance_string] =
              data[:responses].to_f / data[:total].to_f
        end
      end
    end

    probabilities
  end





  def regression(ellipse_ratios, reader_powers, probability_data)
    models = {}

    reader_powers.each do |rp|
      max_degree = 5
      max_degree = 4 if rp >= 28
      models[rp] ||= {}
      ellipse_ratios.each do |er|
        data = Hash[probability_data[rp][er].sort_by{|k,v| k.to_i}]
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

        regression_data_set = regression_data_set.to_dataset
        models[rp][er] =
            Statsample::Regression.multiple(regression_data_set, 'y', {:digits => 10})
      end
    end

    models
  end




  def calculate_correlation(ellipse_ratios, reader_powers, models, probabilities)
    correlation = {}

    reader_powers.each do |rp|
      correlation[rp] ||= {}
      ellipse_ratios.each do |er|
        calc_probabilities = []
        probabilities[rp][er].keys.each do |distance|
          calc_probabilities.push(calculate_probability_by_model(models[rp][er], distance))
        end

        correlation[rp][er] = Math.correlation(probabilities[rp][er].values, calc_probabilities)
      end
    end

    correlation
  end

  def make_graphs(ellipse_ratios, reader_powers, models)
    graphs = {}

    reader_powers.each do |rp|
      graphs[rp] ||= {}
      ellipse_ratios.each do |er|
        graphs[rp][er] = []
        model = models[rp][er]
        (0..700).step(5).each do |distance|
          probability = calculate_probability_by_model(model, distance)
          graphs[rp][er].push([distance.to_f, probability])
        end
      end
    end

    graphs
  end



  def save_models_to_db(ellipse_ratios, reader_powers, models)
    reader_powers.each do |rp|
      ellipse_ratios.each do |er|
        if Regression::ProbabilitiesDistances.where(:ellipse_ratio => er, :reader_power => rp).count == 0
          data = {
              :const => models[rp][er].constant.to_f,
              :dependable => models[rp][er].coeffs.values
          }.to_json

          model = Regression::ProbabilitiesDistances.new({
              :ellipse_ratio => er,
              :reader_power => rp,
              :coeffs => data
          })
          model.save
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