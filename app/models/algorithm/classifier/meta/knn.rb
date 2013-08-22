class Algorithm::Classifier::Meta::Knn < Algorithm::Classifier::Meta

  def set_settings(cut_table)
    @optimization = Optimization::ZonalLeastSquares.new
    @cut_table = cut_table
    self
  end


  private


  def calc_tags_estimates(algorithms, train_height, test_height)
    tags_estimates = {}

    model = train_model(algorithms, train_height)

    TagInput.tag_ids.each do |tag_index|
      tag = TagInput.new(tag_index)
      zone_number = model_run_method(model, algorithms, train_height, test_height, tag.id)
      tag_output = TagOutput.new(tag, Antenna.new(zone_number).coordinates, Zone.new(zone_number))
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end



  def train_model(algorithms, train_height)
    table = {}

    TagInput.tag_ids.each do |tag_index|
      tag = TagInput.new(tag_index)
      input = {}
      algorithms.each do |algorithm_name, algorithm|
        point_estimate = algorithm[:map][train_height][train_height][tag_index][:estimate] rescue nil
        input[algorithm_name] = Antenna.number_from_point(point_estimate)
      end
      table[tag_index] = {}
      table[tag_index][:input] = input
      table[tag_index][:output] = tag.zone
      table[tag_index][:comparison_result] = nil
    end
    table
  end



  def model_run_method(table, algorithms, train_height, test_height, tag_id)
    tag_vector = get_tag_vector(algorithms, train_height, test_height, tag_id)

    if @cut_table
      table_part = table_part_with_tag_vector_zones(table, tag_vector)
    else
      table_part = table
    end

    compare_tag_vector_vs_table_vectors(table_part, tag_vector)
    nearest_neighbour = get_nearest_neighbour(table_part)

    return nil if nearest_neighbour.nil?
    nearest_neighbour.last[:output]
  end







  def get_tag_vector(algorithms, train_height, test_height, tag_id)
    tag_vector = {}
    algorithms.each do |algorithm_name, algorithm|
      point_estimate = algorithm[:map][train_height][test_height][tag_id][:estimate] rescue nil
      tag_vector[algorithm_name] = Antenna.number_from_point(point_estimate)
    end
    tag_vector
  end

  def table_part_with_tag_vector_zones(table, tag_vector)
    table.select{|i, data|tag_vector.values.uniq.include? data[:output]}
  end

  def compare_tag_vector_vs_table_vectors(table_part, tag_vector)
    table_part.values.each do |table_row|
      table_vector = table_row[:input]
      table_row[:comparison_result] = @optimization.compare_vectors(tag_vector, table_vector)
    end
  end

  def get_nearest_neighbour(table_part)
    nearest_neighbours = table_part.sort_by{|k,v|v[:comparison_result]}
    nearest_neighbours.reverse! if @optimization.reverse_decision_function?
    nearest_neighbours.first
  end


end