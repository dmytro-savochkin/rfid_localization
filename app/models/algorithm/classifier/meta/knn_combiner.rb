class Algorithm::Classifier::Meta::KnnCombiner < Algorithm::Classifier::Meta

  attr_accessor :algorithms

  def set_settings(algorithms)
    @algorithms = algorithms
    @optimization = Optimization::ZonalLeastSquares.new
    self
  end


  private


  def calc_tags_estimates(algorithms, train_height, test_height)
    tags_estimates = {}

    model = train_model(algorithms, train_height, test_height)

    TagInput.tag_ids.each do |tag_index|
      tag = TagInput.new(tag_index)
      zone_number = model_run_method(model, algorithms, train_height, test_height, tag)
      tag_output = TagOutput.new(tag, Antenna.new(zone_number).coordinates, Zone.new(zone_number))
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end



  def train_model(algorithms, train_height, test_height)
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



  def model_run_method(table, algorithms, train_height, test_height, tag)
    tag_vector = {}
    algorithms.each do |algorithm_name, algorithm|
      point_estimate = algorithm[:map][train_height][test_height][tag.id][:estimate] rescue nil
      tag_vector[algorithm_name] = Antenna.number_from_point(point_estimate)
    end



    table_part = table.select{|i, data|tag_vector.values.uniq.include? data[:output]}

    if tag.id == 'FF11' and train_height == 1 and test_height == 0
      puts tag.id
      puts '====='
      puts table_part.to_yaml


    end


    table_part.each do |tag_index, table_row|
      table_vector = table_row[:input]

      if tag.id == 'FF11' and train_height == 1 and test_height == 0
        puts 'comparing with ' + tag_index.to_s
        puts tag_vector.to_s
        puts table_vector.to_s
        puts @optimization.compare_vectors(tag_vector, table_vector).to_s
        puts ''
      end

      table_row[:comparison_result] = @optimization.compare_vectors(tag_vector, table_vector)
    end

    nearest_neighbours = table_part.sort_by{|k,v|v[:comparison_result]}
    nearest_neighbours.reverse! if @optimization.reverse_decision_function?
    nearest_neighbour = nearest_neighbours.first


    if tag.id == 'FF11' and train_height == 1 and test_height == 0
      puts nearest_neighbours.to_yaml
      puts '========'
      puts nearest_neighbour.to_s
      puts ''
      puts ''
      puts ''



    end



    return nil if nearest_neighbour.nil?

    nearest_neighbour.last[:output]
  end

end