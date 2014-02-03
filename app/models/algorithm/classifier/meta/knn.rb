class Algorithm::Classifier::Meta::Knn < Algorithm::Classifier::Meta

  def set_settings(cut_table)
    @optimization = Optimization::ZonalLeastSquares.new
    @cut_table = cut_table
    self
  end


  private


  def trainn_model(test_data, height_index)
    table = {}

    test_data.each do |tag_index, tag|
      next if @algorithms.select{|name, a| a[:setup][height_index].keys.include? tag_index}.length == 0

      input = {}
      @algorithms.each do |algorithm_name, algorithm|
        point_estimate = algorithm[:setup][height_index][tag_index].estimate rescue nil
        input[algorithm_name] = Zone.number_from_point(point_estimate)
      end
      table[tag_index] = {}
      table[tag_index][:input] = input
      table[tag_index][:output] = tag.zone
      table[tag_index][:comparison_result] = nil
    end
    table
  end



  def calc_tags_estimates(model, setup, test_data, height_index)
    tags_estimates = {:probabilities => {}, :estimates => {}}

    model = trainn_model(test_data, height_index)

    test_data.each do |tag_index, tag|
      puts tag.id.to_s
      run_results = model_run_method(model, height_index, tag_index)
      #debugger
      zone_probabilities = run_results[:probabilities]
      zone_number = run_results[:result_zone]
      tag_output = TagOutput.new(
          tag,
          Antenna.new(zone_number).coordinates,
          Zone.new(zone_number)
      )
      tags_estimates[:probabilities][tag_index] = zone_probabilities
      tags_estimates[:estimates][tag_index] = tag_output
    end

    tags_estimates
  end




  def model_run_method(table, height_index, tag_id)
    tag_vector = get_tag_vector(height_index, tag_id)

    if @cut_table
      table_part = table_part_with_tag_vector_zones(table, tag_vector)
    else
      table_part = table
    end

    compare_tag_vector_vs_table_vectors(table_part, tag_vector)
    nearest_neighbour = get_nearest_neighbour(table_part)
    return nil if nearest_neighbour.nil?
    result_zone_number = nearest_neighbour.last[:output]

    {
        :result_zone => result_zone_number,
        :probabilities => create_probabilities_for_zone(result_zone_number)
    }
  end





  def create_probabilities_for_zone(result_zone_number)
    probabilities = {}
    (1..16).each do |zone_number|
      if zone_number == result_zone_number.to_i
        probabilities[zone_number] = 1.0
      else
        probabilities[zone_number] = 0.5
      end
    end
    probabilities
  end





  def get_tag_vector(height_index, tag_id)
    tag_vector = {}
    @algorithms.each do |algorithm_name, algorithm|
      point_estimate = algorithm[:map][height_index][tag_id][:estimate] rescue nil
      tag_vector[algorithm_name] = Antenna.number_from_point(point_estimate)
    end
    tag_vector
  end

  def table_part_with_tag_vector_zones(table, tag_vector)
    table.select{|i, data|tag_vector.values.uniq.include? data[:output]}
  end

  def compare_tag_vector_vs_table_vectors(table_part, tag_vector)
    weights = {}
    table_part.values.each do |table_row|
      table_vector = table_row[:input]
      table_row[:comparison_result] =
          @optimization.compare_vectors(tag_vector, table_vector, weights)
    end
  end

  def get_nearest_neighbour(table_part)
    nearest_neighbours = table_part.sort_by{|k,v|v[:comparison_result]}
    nearest_neighbours.reverse! if @optimization.reverse_decision_function?
    nearest_neighbours.first
  end


end