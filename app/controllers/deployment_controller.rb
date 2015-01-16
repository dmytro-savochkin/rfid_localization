require 'mi/base'
require 'mi/a'
require 'algorithm/point_based/zonal/zones_creator'
require 'deployment/method/combinational'
require 'deployment/method/single/trilateration'
require 'deployment/method/single/fingerprinting'
require 'deployment/method/single/intersectional'

class DeploymentController < ApplicationController
	require_dependency 'work_zone'
	require_dependency 'antenna'
	require_dependency 'point'



	def heuristic
		@optimization_name = :simulated_annealing
		optimization_clazz = ('Deployment::Optimization::' + @optimization_name.to_s.camelize).constantize
		antenna_manager = Deployment::AntennaManager.new(16)
		combinational = Deployment::Method::Combinational.new
		optimizer = optimization_clazz.new(antenna_manager, combinational)
		history, best_solutions = optimizer.search_for_optimum
		best_solution = best_solutions.sort_by{|p| p.score}.last
		@score = best_solution.score
		@results = best_solution.results
		@rates = best_solution.rates
		@score_map = best_solution.score_map
		@history = history
		@best_solutions = best_solutions

		render 'deployment'
	end




	def pattern
		results = {}
		scores = {}
		(115..115).step(5).each do |shift|
			results[shift] = {}
			scores[shift] = {}
			(0.25*Math::PI..0.25*Math::PI).step(0.25*Math::PI).each do |rotation|
				#rotation = 0.0
				puts shift.to_s + ' ' + rotation.to_s
				antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], rotation, :grid)
				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], :to_center, :grid)

				#antennae = WorkZone.create_default_antennae(13, shift, [250,160], [300,190], rotation, :triangular)
				#antennae = WorkZone.create_default_antennae(13, shift, [250,160], [300,190], :to_center, :triangular)

				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], rotation, :triangular2)
				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], :to_center, :triangular2)

				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], rotation, :square, {at_center: true})
				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], :to_center, :square, {at_center: true})
				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], rotation, :square)
				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], :to_center, :square)

				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], rotation, :square2, {at_center: true})
				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], :to_center, :square2, {at_center: true})

				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], rotation, :round, {at_center: true})
				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], :to_center, :round, {at_center: true})
				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], rotation, :round)
				#antennae = WorkZone.create_default_antennae(16, shift, [250,160], [300,190], :to_center, :round)

				combinational = Deployment::Method::Combinational.new
				current_solution, current_score, current_rates, score_map = combinational.calculate_score(antennae)
				scores[shift][rotation] = current_score
				results[shift][rotation] = {
						solution: current_solution,
						score: current_score,
						rates: current_rates,
						score_map: score_map
				}
			end
		end
		best_result = {score: 0.0}
		results.each do |shift, results_|
			puts 'SHIFT: ' + shift.to_s
			results_.each do |rotation, result|
				best_result = result if result[:score] > best_result[:score]
				puts rotation.round(2).to_s + ' ' + result[:score].to_s
			end
			puts '----'
		end
		@score = best_result[:score]
		@results = best_result[:solution]
		@rates = best_result[:rates]
		@scores = scores
		@score_map = best_result[:score_map]

		render 'deployment'
	end


end