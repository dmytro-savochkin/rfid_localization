class Algorithm::Classifier::Neural::FannWithDistancesTraining < RubyFann::Standard
  attr_reader :error_sum
  attr_accessor :algorithm, :train_input

  def training_callback(args)
    @error_sum = 0.0
    @train_input.values.each do |tag|
      coords =
          Antenna.new( @algorithm.send(:model_run_method, self, tag) ).coordinates
      @error_sum += tag.position.distance_to_point(coords)
    end
    @error_sum /= @algorithm.tags_for_table.length

    accepted_error = 55.0
    accepted_error = 55.0 if @algorithm.reader_power == 23
    accepted_error = 60.0 if @algorithm.reader_power == 23
    accepted_error = 65.0 if @algorithm.reader_power >= 25

    if @error_sum < accepted_error
      return -1
    end
    0
  end
end