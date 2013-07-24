class Algorithm::Neural::FeedForward::Ai4r < Algorithm::Neural
  def train_network
    network = Ai4r::NeuralNetwork::Backpropagation.new([16, 16, 2])

    500.times do
      @tags_for_table.values.each do |tag|
        input_vector = add_empty_values_to_vector(tag)
        output_vector = tag.position.to_a.map{|coord| coord.to_f / WorkZone::WIDTH}
        network.train(input_vector, output_vector)
      end
    end

    network
  end

  def make_estimate(network, tag)
    tag_data = add_empty_values_to_vector(tag)
    tag_estimate_as_a = network.eval( tag_data )
    Point.from_a( tag_estimate_as_a.map{|c|c * WorkZone::WIDTH} )
  end
end