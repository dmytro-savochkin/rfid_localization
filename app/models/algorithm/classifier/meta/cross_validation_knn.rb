class Algorithm::Classifier::Meta::CrossValidationKnn < Algorithm::Classifier::Meta::Knn



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

      ((0..3).to_a - [train_height]).each do |meta_train_height|
        @output[train_height][meta_train_height] ||= {}
        @map[train_height][meta_train_height] ||= {}
        @classification_success[train_height][meta_train_height] ||= {}
        @classification_parameters[train_height][meta_train_height] ||= {}

        ((0..3).to_a - [train_height, meta_train_height]).each do |test_height|
          @output[train_height][meta_train_height][test_height] =
              execute_tags_estimates_search(models, train_height, meta_train_height, test_height)

          @map[train_height][meta_train_height][test_height] = {}
          TagInput.tag_ids.each do |tag_index|
            tags[tag_index] ||= TagInput.new(tag_index)
            tag = tags[tag_index]
            if @output[train_height][meta_train_height][test_height][tag_index] != nil and tag != nil
              @map[train_height][meta_train_height][test_height][tag_index] = {
                  :position => tag.position,
                  :estimate => @output[train_height][meta_train_height][test_height][tag_index].estimate,
                  :error =>
                      Zone.distance_score_for_zones(
                          @output[train_height][meta_train_height][test_height][tag_index].zone_estimate,
                          Zone.new(tag.zone)
                      )
              }
            end
          end

          @classification_success[train_height][meta_train_height][test_height] =
              calc_classification_success(@output[train_height][meta_train_height][test_height])

          @classification_parameters[train_height][meta_train_height][test_height] =
              calc_classification_parameters(@output[train_height][meta_train_height][test_height])
        end

      end
    end

    self
  end





  private

  def execute_tags_estimates_search(models, train_height, meta_train_height, test_height)
    calc_tags_estimates(@algorithms, train_height, meta_train_height, test_height)
  end






  def calc_tags_estimates(algorithms, train_height, meta_train_height, test_height)
    tags_estimates = {}

    model = train_model(algorithms, train_height, meta_train_height)

    TagInput.tag_ids.each do |tag_index|
      tag = TagInput.new(tag_index)
      zone_number = model_run_method(model, algorithms, train_height, test_height, tag.id)
      tag_output = TagOutput.new(tag, Antenna.new(zone_number).coordinates, Zone.new(zone_number))
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end



  def train_model(algorithms, train_height, meta_train_height)
    table = {}

    TagInput.tag_ids.each do |tag_index|
      tag = TagInput.new(tag_index)
      input = {}
      algorithms.each do |algorithm_name, algorithm|
        point_estimate = algorithm[:map][train_height][meta_train_height][tag_index][:estimate] rescue nil
        input[algorithm_name] = Antenna.number_from_point(point_estimate)
      end
      table[tag_index] = {}
      table[tag_index][:input] = input
      table[tag_index][:output] = tag.zone
      table[tag_index][:comparison_result] = nil
    end

    table
  end

end