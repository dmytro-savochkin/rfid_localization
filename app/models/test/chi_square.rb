class Test::ChiSquare
	require 'rinruby'

	CONFIDENCE_LEVEL = 0.999
	STEPS = 20

	def initialize
		@rinruby = RinRuby.new(echo = false)
	end


	def test_normality(data)
		data_min = data.min.to_f
		data_max = data.max.to_f
		step_size = (data_max - data_min) / STEPS
		generator = Rubystats::NormalDistribution.new(data.mean, data.stddev)

		histogram = []
		ideal_histogram = []

		start = data_min
		STEPS.times do |i|
			probability = data.select do |d|
				if i < (STEPS - 1)
					start <= d and d < (start + step_size)
				else
					start <= d and d <= (start + step_size)
				end
			end.length.to_f
			ideal_probability = (generator.cdf(start + step_size) - generator.cdf(start)) * data.length

			histogram.push probability
			ideal_histogram.push ideal_probability

			start += step_size
		end



		chi_square = 0.0
		histogram.each_with_index do |probability, i|
			chi_square += ((probability - ideal_histogram[i]) ** 2) / ideal_histogram[i]
			puts (((probability - ideal_histogram[i]) ** 2) / ideal_histogram[i]).to_s
		end

		puts histogram.to_s
		puts ideal_histogram.to_s
		puts ''

		percentile = 1.0 - CONFIDENCE_LEVEL
		@rinruby.eval "quantile <- toString(qchisq(#{percentile}, df=#{(STEPS-3).to_s}))"
		quantile = @rinruby.pull("quantile").to_f


		#puts histogram.to_s
		#puts ideal_histogram.to_s

		[chi_square, quantile, chi_square < quantile]
	end

end