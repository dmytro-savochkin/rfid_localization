class Algorithm::Classifier::Classifier < Algorithm::Base

  attr_reader :tags_for_table

  def set_settings(metric_name = :rss, tags_for_table)
    @metric_name = metric_name
    @mi_class = MeasurementInformation::Base.class_by_mi_type(metric_name)
    @tags_for_table = tags_for_table
    self
  end



  private


  def calculate_tags_output
    tags_estimates = {}

    model = train_model
    @training_result = calc_training_result(model)

    @tags.each do |tag_index, tag|
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


  def calc_training_result(model)
    if @tags_for_table.present?
      training_estimates = {}
      @tags_for_table.each do |tag_index, tag|
        zone = Zone.new(model_run_method(model, tag))
        training_estimates[tag_index] = TagOutput.new(tag, zone.coordinates, zone)
      end
      training_estimates
    end
  end







  def calc_classifying_success(tags_output)
    @classifying_success = {:train => Hash.new(0.0), :test => Hash.new(0.0)}

    input_output_for_types = {
        :test => {:input => @tags, :output => tags_output},
        :train => {:input => @tags_for_table, :output => @training_result}
    }
    input_output_for_types.each do |type, input_output|
      input = input_output[:input]
      output = input_output[:output]

      if input.present?

        tag_indices_by_zones = {}
        input.values.each do |tag|
          tag_real_zone = tag.nearest_antenna.number
          tag_indices_by_zones[tag_real_zone] ||= []
          tag_indices_by_zones[tag_real_zone].push tag.id.to_s
        end

        tag_indices_by_zones.each do |zone_number, tag_indices_in_zone|
          tag_indices_in_zone = tag_indices_in_zone.reject{|tag_index|output[tag_index].nil?}

          success_rate = 1.0 / tag_indices_in_zone.length
          tag_indices_in_zone.each do |tag_index|
            zone_estimate = output[tag_index].zone_estimates.number
            @classifying_success[type][zone_number] += success_rate if zone_number == zone_estimate.to_i
          end
          @classifying_success[type][zone_number] = 1.0 if @classifying_success[type][zone_number] > 1.0
        end

      end
    end

  end


  def calc_classification_parameters
    @classification_parameters = {}

    tags_count_with_no_input = @tags_output.values.select(&:nil?).length

    zone_errors_types = %w(ok error not_found)
    zone_errors_types.each do |type|
      @classification_parameters[type.to_sym] =
          @tags_output.values.select{|tag|tag.zone_error_code == type.to_sym}.length
    end
    @classification_parameters[:not_found] += tags_count_with_no_input
    @classification_parameters[:success] =
        (@classification_parameters[:ok].to_f / TagInput.tag_ids.length).round(4)
  end








  def tag_answers(tag)
    (1..16).map{|antenna| tag.answers[@metric_name][:average][antenna] || @mi_class.default_value}
  end

end