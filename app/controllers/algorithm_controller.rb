require 'mi/base'
require 'mi/a'
require 'algorithm/point_based/zonal/zones_creator'

class AlgorithmController < ApplicationController
	require_dependency 'work_zone'
	require_dependency 'parser'
	require_dependency 'antenna'
	require_dependency 'tag_input'
	require_dependency 'point'
	require_dependency 'regression'
	require_dependency 'regression/distances_mi'
	require_dependency 'regression/probabilities_distances'


	def classifier
		algorithm_runner = AlgorithmRunner.new
		@mi = algorithm_runner.mi
		algorithms, @tags_input = algorithm_runner.run_classifiers_algorithms
		@algorithms = clean_algorithms_data(algorithms, [:classification_parameters, :map, :reader_power, :heights_combinations])
		#@algorithms = clean_algorithms_data(algorithms)
	end


	def point_based
		algorithm_runner = AlgorithmRunner.new
		@mi = algorithm_runner.mi

		algorithms = algorithm_runner.run_point_based_algorithms
		@algorithms = clean_algorithms_data(algorithms)

		#@tags_reads_by_antennae_count = algorithm_runner.calc_tags_reads_by_antennae_count
		#@ac = algorithm_runner.calc_antennae_coefficients

		#@trilateration_map_data = algorithm_runner.trilateration_map
	end


	def combinational
		algorithm_runner = AlgorithmRunner.new
		algorithms, classifiers, manager = algorithm_runner.run_algorithms_with_classifying
		#@algorithms = clean_algorithms_data(algorithms, [:errors_parameters])
		@algorithms = clean_algorithms_data(algorithms)
		@classifiers = clean_classifier_data(classifiers)

		if manager.generator
			@generator_data = {
					:cache => {
							:rss => manager.generator.error_generator.rss_error_cache,
							:number => manager.generator.error_generator.response_probability_number_cache
					},
					:rss_errors => manager.generator.rss_errors,
					:rss_rr_correlation => Math.correlation(
							manager.generator.values[:rss],
							manager.generator.values[:rr]
					)
			}
		else
			@generator_data = {}
		end


		#@trilateration_map_data = algorithm_runner.linear_trilateration_map
		#@tags_reads_by_antennae_count = algorithm_runner.calc_tags_reads_by_antennae_count
		#@ac = algorithm_runner.calc_antennae_coefficients(tags_input, @algorithms)
	end









	private



	def clean_classifier_data(classifiers)
		hash = Hash.new

		classifiers.each do |classifier_name, classifier|
			hash[classifier_name] ||= {}
			[:probabilities, :classification_success].each do |var_name|
				if classifier.respond_to?(var_name)
					hash[classifier_name][var_name] = classifier.send(var_name)
				end
			end
		end

		hash
	end

end