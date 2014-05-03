class Algorithm::Classifier < Algorithm::Base

  attr_reader :classification_success, :classification_parameters, :map, :probabilities




  private

  def specific_output(model, test_data, index)
    @classification_success ||= {}
    @classification_parameters ||= {}
    @probabilities ||= {}

    raw_output = calc_tags_estimates(model, @setup[index], test_data, index)
    if raw_output[:estimates].present?
      output = raw_output[:estimates]
      @probabilities[index] = probabilities_keys_to_points(raw_output[:probabilities])
    else
      output = raw_output
    end

    @map[index] = {}
    test_data.each do |tag_index, tag|
      if output[tag_index] != nil and tag != nil
        @map[index][tag_index] = {
            :position => tag.position,
            :estimate => output[tag_index].estimate,
            :error => Zone.distance_score_for_zones(
                output[tag_index].zone_estimate,
                Zone.new(tag.zone)
            )
        }
      end
    end

    @classification_success[index] = calc_classification_success(output, test_data)
    @classification_parameters[index] = calc_classification_parameters(output, test_data)
  end




  def calc_tags_estimates(model, setup, input_tags, height_index)
    tags_estimates = {:probabilities => {}, :estimates => {}}

    input_tags.each do |tag_index, tag|
      run_results = model_run_method(model, setup, tag)
      zone_probabilities = run_results[:probabilities]
      zone_estimate = run_results[:result_zone]
      zone = Zone.new(zone_estimate)
      tag_output = TagOutput.new(tag, zone.coordinates, zone)
      tags_estimates[:probabilities][tag_index] = zone_probabilities
      tags_estimates[:estimates][tag_index] = tag_output
    end

    tags_estimates
  end






  def set_up_model(model, train_data, setup_data, height_index)
    tags_estimates = {}
    tags_probabilities = {}
    tags_errors = {:all => 0}
    setup_data.each do |tag_index, tag|
      run_results = model_run_method(model, nil, tag)
      zone_estimate = run_results[:result_zone]
      zone_probabilities = run_results[:probabilities]
      zone = Zone.new(zone_estimate)
      tag_output = TagOutput.new(tag, zone.coordinates, zone)
      tags_estimates[tag_index] = tag_output
      tags_probabilities[tag_index] = zone_probabilities


      tags_errors[tag.zone.to_i] ||= 0
      if tags_estimates[tag_index].zone_estimate.number != tag.zone
        tags_errors[:all] += 1
        tags_errors[tag.zone.to_i] += 1
      end
    end

    success_rate = {:all => nil, :by_zones => {}}
    setup_data.each do |tag_index, tag|
      success_rate[:all] = (setup_data.length.to_f - tags_errors[:all].to_f) / setup_data.length
      (1..16).each do |zone_number|
        length = setup_data.values.select{|tag| tag.zone == zone_number}.length
        success_rate[zone_number] = (length - tags_errors[zone_number].to_f) / length
      end
    end


    retrained_model = retrain_model(train_data, setup_data, @heights_combinations[height_index])

    {
        :estimates => tags_estimates,
        :probabilities => tags_probabilities,
        :retrained_model => retrained_model,
        :success_rate => success_rate
    }
  end












  def probabilities_keys_to_points(probabilities)
    return nil if probabilities.nil?
    converted_probabilities = {}
    probabilities.each do |tag, probabilities_for_tag|
      converted_probabilities[tag] = {}
      probabilities_for_tag.each do |zone_number, probability|
        converted_probabilities[tag][Zone.new(zone_number).coordinates] = probability
      end
    end
    converted_probabilities
  end



  def desired_accuracies(height)
    ([0.0] * 4)[height]
  end

  def calc_accuracy(model, tags)
    errors = 0
    tags.values.each do |tag|
      errors += 1 if model_run_method(model, nil, tag)[:result_zone] != tag.zone
    end
    (tags.length - errors).to_f / tags.length
  end















  def calc_classification_success(output, input_tags)
    classification_success = Hash.new(0.0)

    tag_indices_by_zones = {}
    input_tags.each do |tag_index, tag|
      tag_real_zone = tag.zone
      tag_indices_by_zones[tag_real_zone] ||= []
      tag_indices_by_zones[tag_real_zone].push tag_index.to_s
    end

    (1..16).each do |zone_number|
      classification_success[zone_number] = 0.0
    end

    tag_indices_by_zones.each do |zone_number, tag_indices_in_zone|
      tag_indices_in_zone = tag_indices_in_zone.reject{|tag_index|output[tag_index].nil?}

      tag_indices_in_zone.each do |tag_index|
        zone_estimate = output[tag_index].zone_estimate.number
        classification_success[zone_number] += 1 if zone_number == zone_estimate.to_i
      end
      #classification_success[zone_number] = 1.0 if classification_success[zone_number] > 1.0
    end
    classification_success['all'] = classification_success.values.sum.to_f / input_tags.length

    (1..16).each do |zone_number|
      classification_success[zone_number] = classification_success[zone_number]
          #' out of ' +
          #input_tags.values.select{|tag|tag.zone == zone_number}.length.to_s
    end


    classification_success
  end




  def calc_classification_parameters(output, input_tags)
    classification_parameters = {}
    tags_count_with_no_input = output.values.select(&:nil?).length

    zone_errors_types = %w(ok error not_found)
    zone_errors_types.each do |type|
      classification_parameters[type.to_sym] =
          output.values.select{|tag|tag.zone_error_code == type.to_sym}.length
    end
    classification_parameters[:not_found] += tags_count_with_no_input
    classification_parameters[:success] =
        (classification_parameters[:ok].to_f / input_tags.length).round(4)

    classification_parameters
  end











  #def create_model_object(train_data, height)
  #  klass = self.class.to_s.demodulize.underscore
  #  algorithm_type = self.class.to_s.split('::')[-2].underscore
  #  models_path = Rails.root.to_s + "/app/models/algorithm/" + algorithm_type + "/models/" + klass + '/'
  #
  #  if save_in_file_by_external_mechanism
  #    Dir.mkdir(models_path) unless File.directory?(models_path)
  #    model_file_prefix = @reader_power.to_s + '_' + height.to_s + '_' + @metric_name.to_s + '_'
  #    files = Dir.glob(models_path + model_file_prefix + '*')
  #    if files.length > 0
  #      marshalled_model = File.read(files.first)
  #      model = Marshal.load(marshalled_model)
  #    else
  #      model = train_model(train_data, height)
  #      marshalled_model = Marshal.dump(model)
  #      model_accuracy = calc_accuracy(model, train_data)
  #      model_file_name = model_file_prefix + model_accuracy.to_s
  #      File.open(models_path + model_file_name, 'wb') { |file| file.write( marshalled_model ) }
  #    end
  #  else
  #    model = train_model(train_data, height)
  #  end
  #
  #  model
  #end


  def model_file_dir
    Rails.root.to_s + '/app/models/algorithm/classifier/models/undefined/'
  end
  def model_file_prefix(height)
    @reader_power.to_s + '_' + height.to_s + '_' + @metric_name.to_s
  end
  def model_file_mask(height)
    model_file_prefix(height) + '_[\d\.]+'
  end
  def get_model_file(height)
    file_reg_exp = Regexp.new(model_file_mask(height))
    files = Dir.entries(model_file_dir).select do |f|
      good = File.file?(model_file_dir.to_s + f.to_s) && file_reg_exp.match(f)
      good
    end
    return nil if files.first.nil?
    model_file_dir.to_s + files.first
  end




  def required_probabilities_for_tag(tag)
    probabilities = {}
    (1..16).each do |zone_number|
      zone_score = Zone.distance_score_for_zones(Zone.new(tag.zone), Zone.new(zone_number))
      probabilities[zone_number] = 1.0 / (1.0 + zone_score ** 2)
    end
    probabilities
  end
  def zero_zone_probabilities
    probabilities = {}
    (1..16).each{|zone_number| probabilities[zone_number] = 0.0}
    probabilities
  end
  def unity_zone_probabilities
    probabilities = {}
    (1..16).each{|zone_number| probabilities[zone_number] = 1.0}
    probabilities
  end

end