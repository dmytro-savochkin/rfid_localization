class Algorithm::PointBased::Neural::Fann < RubyFann::Standard
  attr_reader :error_sum
  attr_accessor :algorithm, :train_input

  def training_callback(args)
    @error_sum = 0.0
    @train_input.values.each do |tag|
      coords = @algorithm.send(:model_run_method, self, tag)
      @error_sum += tag.position.distance_to_point(coords)
    end
    @error_sum /= @train_input.length

    accepted_error = 7.0

    puts @error_sum.to_s
    if @error_sum < accepted_error
      return -1
    end
    0
  end
end