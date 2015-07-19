class ApplicationController < ActionController::Base
  protect_from_forgery


	private

	def clean_algorithms_data(algorithms, keys = nil)
		algorithms.each do |algorithm_name, algorithm|
			hash = Hash.new
			if keys.nil?
				keys = [
						:map, :reader_power, :errors_parameters, :cdf, :pdf, :map, :errors, :best_suited,
						:tags_input, :heights_combinations, :setup, :probabilities_with_zones_keys,
						:classification_parameters, :classification_success, :work_zone, :group
				]
			end
			keys.each do |var_name|
				hash[var_name] = algorithm.send(var_name) if algorithm.respond_to?(var_name)
			end
			if algorithm.instance_variable_defined?("@algorithms")
				hash[:combiner] = true
			else
				hash[:combiner] = false
			end
			algorithms[algorithm_name] = hash
		end
		algorithms
	end
end
