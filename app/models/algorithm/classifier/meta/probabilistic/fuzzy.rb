class Algorithm::Classifier::Meta::Probabilistic::Fuzzy < Algorithm::Classifier::Meta::Probabilistic

  private

  def set_up_model(model, train_data, setup_data, height_index)
    weights = {}
    @algorithms.values.each_with_index do |algorithm, algorithm_index|
      weights[algorithm_index] = algorithm[:setup][height_index][:success_rate][:all].to_f
    end
    lambda = calculate_lambda(weights)
    {:weights => weights, :lambda => lambda}
  end


  def calculate_lambda(algorithm_weights)
    g = algorithm_weights.values
    g_product = g.general_product
    polynomial_roots = g.map{|g_i| -1.0/g_i}
    polynomial_coefficients = Math.polynomial_coefficients_by_roots(polynomial_roots)
    polynomial_coefficients = polynomial_coefficients.map{|v| v * g_product}
    polynomial_coefficients[-1] -= 1
    polynomial_coefficients[-2] -= 1
    require 'rinruby'
    R.eval "x <- toString(polyroot(c(#{polynomial_coefficients.reverse.to_s.gsub(/[\[\]]/, '')})))"
    roots = R.pull("x").to_s.split(',').map{|v| Complex(v)}
    found_root = roots.select do |root|
      root.imaginary.abs <= 0.000001 and root.real >= -1.00001 and root.abs > 0.001
    end
    found_root.first.real
  end



  #def rescale_confidence(confidence)
  #  confidence
  #end


  def make_estimate(tag_index, setup, height_index)
    probabilities = {}

    weights = setup[:weights]
    lambda = setup[:lambda]

    (1..16).each do |zone_number|
      zone_center = Zone.new(zone_number).coordinates
      algorithms_probabilities = @algorithms.values.each_with_index.map do |algorithm, index|
        [
            weights[index],
            rescale_confidence(
                algorithm[:probabilities][height_index][tag_index].select do |center, ps|
                  center.to_s == zone_center.to_s
                end.values.first
            )
        ]
      end
      sorted_algorithms_probabilities = algorithms_probabilities.sort_by{|v| -v.last}

      g = []
      g.push sorted_algorithms_probabilities.first[0]
      (1...@algorithms.length).each do |t|
        g.push(sorted_algorithms_probabilities[t][0] + g[t-1] + lambda * sorted_algorithms_probabilities[t][0] * g[t-1])
      end

      #zone_probability =
      #    (g.each_with_index.map{|g_i, i| [g_i, sorted_algorithms_probabilities[i][1]].min}).max
      #puts zone_probability.to_s

      zone_probability =
          sorted_algorithms_probabilities[0][1] +
          (g[1..-1].each_with_index.map{|g_i, i| g[i-1] * (sorted_algorithms_probabilities[i-1][1] - sorted_algorithms_probabilities[i][1])}).sum
      #puts zone_probability.to_s
      #puts ''


      probabilities[zone_number] = zone_probability
    end

    {
        :probabilities => probabilities,
        :result_zone => probabilities.key(probabilities.values.max)
    }
  end

end