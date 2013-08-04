class Algorithm::PointBased::Neural::FannWithDistancesTraining < RubyFann::Standard
  attr_reader :error_sum
  attr_accessor :algorithm

  def training_callback(args)
    @error_sum = 0.0
    @algorithm.tags_for_table.values.each do |tag|
      coords = @algorithm.send(:make_estimate, self, tag)
      @error_sum += tag.position.distance_to_point(coords)
    end
    @error_sum /= @algorithm.tags_for_table.length

    accepted_error = 5.0

    if @error_sum < accepted_error
      return -1
    end
    0
  end
end



class Algorithm::PointBased::Neural::FeedForward::Fann < Algorithm::PointBased::Neural
  def train_network(hidden_neurons_count = 16)
    fann_class = Algorithm::PointBased::Neural::FannWithDistancesTraining

    input_vector = []
    output_vector = []
    @tags_for_table.values.each do |tag|
      input_vector.push add_empty_values_to_vector(tag)
      output_vector.push tag.position.to_a.map{|coord| coord.to_f / WorkZone::WIDTH}
    end

    train = RubyFann::TrainData.new(
        :inputs => input_vector,
        :desired_outputs => output_vector)
    fann = fann_class.new(:num_inputs => 16, :hidden_neurons => [hidden_neurons_count], :num_outputs => 2)
    fann.algorithm = self

    max_epochs = 50_000
    desired_mse = 0.001
    epochs_log_step = 500
    fann.train_on_data(train, max_epochs, epochs_log_step, desired_mse)
    fann
  end

  def make_estimate(network, tag)
    tag_data = add_empty_values_to_vector(tag)
    tag_estimate_as_a = network.run( tag_data )
    Point.from_a( tag_estimate_as_a.map{|c|c * WorkZone::WIDTH} )
  end
end