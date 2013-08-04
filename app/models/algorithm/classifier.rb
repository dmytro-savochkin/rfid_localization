class Algorithm::Classifier < Algorithm::Base

  attr_reader :tags_input, :classification_success, :output, :classification_parameters


  def set_settings(metric_name = :rss, train_data)
    @metric_name = metric_name
    @mi_class = MeasurementInformation::Base.class_by_mi_type(metric_name)
    @tags_input = train_data
    self
  end




  def output()
    models = create_models_object

    @output = {}
    @map = {}
    @classification_success = {}
    @classification_parameters = {}

    tags = {}

    (0..3).each do |train_height|
      @output[train_height] ||= {}
      @map[train_height] ||= {}
      @classification_success[train_height] ||= {}
      @classification_parameters[train_height] ||= {}

      (0..3).each do |test_height|
        @output[train_height][test_height] = execute_tags_estimates_search(models, train_height, test_height)

        @map[train_height][test_height] = {}
        TagInput.tag_ids.each do |tag_index|
          tags[tag_index] ||= TagInput.new(tag_index)
          tag = tags[tag_index]
          if @output[train_height][test_height][tag_index] != nil and tag != nil
            @map[train_height][test_height][tag_index] = {
                :position => tag.position,
                :estimate => @output[train_height][test_height][tag_index].estimate,
                :error =>
                    Zone.distance_score_for_zones(
                        @output[train_height][test_height][tag_index].zone_estimate,
                        Zone.new(tag.zone)
                    )
            }
          end
        end

        @classification_success[train_height][test_height] =
            calc_classification_success(@output[train_height][test_height])

        @classification_parameters[train_height][test_height] =
            calc_classification_parameters(@output[train_height][test_height])
      end
    end


    self
  end





  private


  def create_models_object
    models = []
    (0..3).each do |height|
      models.push( train_model(@tags_input[height]) )
    end
    models
  end

  def execute_tags_estimates_search(models, train_height, test_height)
    calc_tags_estimates(models[train_height], @tags_input[test_height])
  end





  def calc_tags_estimates(model, input_tags)
    tags_estimates = {}

    input_tags.each do |tag_index, tag|
      zone_estimate = model_run_method(model, tag)

      zone = Zone.new(zone_estimate)
      if zone.coordinates.nil?
        tag_output = TagOutput.new(tag, Point.new(nil,nil), zone)
      else
        tag_output = TagOutput.new(tag, zone.coordinates, zone)
      end
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end









  def calc_classification_success(output)
    classification_success = Hash.new(0.0)

    tag_indices_by_zones = {}
    TagInput.tag_ids.each do |tag_index|
      tag_real_zone = TagInput.new(tag_index).nearest_antenna.number
      tag_indices_by_zones[tag_real_zone] ||= []
      tag_indices_by_zones[tag_real_zone].push tag_index.to_s
    end

    tag_indices_by_zones.each do |zone_number, tag_indices_in_zone|
      tag_indices_in_zone = tag_indices_in_zone.reject{|tag_index|output[tag_index].nil?}

      success_rate = 1.0 / tag_indices_in_zone.length
      tag_indices_in_zone.each do |tag_index|
        zone_estimate = output[tag_index].zone_estimate.number
        classification_success[zone_number] += success_rate if zone_number == zone_estimate.to_i
      end
      classification_success[zone_number] = 1.0 if classification_success[zone_number] > 1.0
    end


    classification_success
  end




  def calc_classification_parameters(output)
    classification_parameters = {}
    tags_count_with_no_input = output.values.select(&:nil?).length

    zone_errors_types = %w(ok error not_found)
    zone_errors_types.each do |type|
      classification_parameters[type.to_sym] =
          output.values.select{|tag|tag.zone_error_code == type.to_sym}.length
    end
    classification_parameters[:not_found] += tags_count_with_no_input
    classification_parameters[:success] =
        (classification_parameters[:ok].to_f / TagInput.tag_ids.length).round(4)

    classification_parameters
  end








  def tag_answers(tag)
    (1..16).map{|antenna| tag.answers[@metric_name][:average][antenna] || @mi_class.default_value}
  end

end