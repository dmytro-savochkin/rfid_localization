class Optimization::L3Distance < Optimization::LeastSquares
  private

  def criterion_function(value1, value2, double_sigma_power = nil)
    (value1 - value2).abs ** 3
  end

end