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


		# THERE CANNOT BE BOTH OBSTRUCTIONS AND PASSAGES INSIDE SAME AREA !

		obstructions = [
				#Deployment::Obstruction::Rectangle.new(Point.new(250,250), 400, 30),
				#Deployment::Obstruction::Rectangle.new(Point.new(200,200), 400, 400),
				#Deployment::Obstruction::Rectangle.new(Point.new(250,250), 30, 400)
				#Deployment::Obstruction::Rectangle.new(Point.new(125,125), 250, 250)
		]
		passages = [
				#Deployment::Passage::Rectangle.new(Point.new(250,250), 500, 80)
				Deployment::Passage::Rectangle.new(Point.new(125,125), 250, 250)
		]
		antenna_manager = Deployment::AntennaManager.new(16, obstructions, passages)
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
		@obstruction = obstructions.first
		@passage = passages.first

		render 'deployment'
	end



	def specific_pattern
		respond_to do |format|
			format.js {
				antenna_group = Deployment::AntennaGroup.from_s(params['deployment_string'])
				combinational = Deployment::Method::Combinational.new
				current_solution, current_score, current_rates, score_map = combinational.calculate_score(antenna_group.data)
				@score = current_score
				result = {
						solution: current_solution,
						score: current_score,
						rates: current_rates,
						score_map: score_map,
						antennae: antenna_group
				}
				@results = result[:solution]
				@rates = result[:rates]
				@score_map = result[:score_map]
				s = render_to_string('deployment', :layout => false)
				render :json => s.to_json
			}
			format.html
		end
	end


	def pattern
		results = {}
		scores = {}
		(65..65).step(5).each do |shift|
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
						score_map: score_map,
						antennae: Deployment::AntennaGroup.new(antennae.values)
				}
			end
		end
		best_solutions = []
		best_result = {score: 0.0}
		results.each do |shift, results_|
			puts 'SHIFT: ' + shift.to_s
			results_.each do |rotation, result|
				best_result = result if result[:score] > best_result[:score]
				best_solutions.push result[:antennae]
				puts rotation.round(2).to_s + ' ' + result[:score].to_s
			end
			puts '----'
		end
		@score = best_result[:score]
		@results = best_result[:solution]
		@rates = best_result[:rates]
		@scores = scores
		@score_map = best_result[:score_map]
		@best_solutions = best_solutions

		render 'deployment'
	end





	def verification
		antenna_manager = Deployment::AntennaManager.new(16)
		combinational = Deployment::Method::Combinational.new
		deployments = {}


		#(50..50).step(10).each do |shift|
		##(50..90).step(10).each do |shift|
		##	[Math::PI/2, :to_center].each do |rotation|
		#	[Math::PI/2].each do |rotation|
		#		[:grid].each do |pattern|
		#			small_coverage_zones = Deployment::AntennaManager::COVERAGE_ZONE_SIZES.first[:small]
		#			big_coverage_zones = Deployment::AntennaManager::COVERAGE_ZONE_SIZES.first[:big]
		#			antennae = WorkZone.create_default_antennae(16, shift, small_coverage_zones, big_coverage_zones, rotation, :grid)
		#			antenna_group = Deployment::AntennaGroup.new(antennae.values)
		#			deployments[pattern.to_s+'-'+shift.to_s+'-'+rotation.to_s] = antenna_group.data
		#		end
		#	end
		#end
		#puts 'pattern deployments processed'

		dir_path = Rails.root.to_s + '/app/raw_input/deployments/'
		Dir.entries(dir_path).select do |f|
			if f.to_s != '.' and f.to_s != '..' and f.to_s == 'sa'
				File.readlines(dir_path + f).each_with_index do |deployment_string, i|
					antenna_group = Deployment::AntennaGroup.from_s(deployment_string)
					deployments[f.to_s+'-'+i.to_s] = antenna_group.data
				end
			end
		end
		puts 'heuristic deployments processed'

		#(0...1).each do |i|
		#	puts 'deployment ' + i.to_s
		#	deployments[i] = antenna_manager.create_random_group()
		#end
		#puts 'random deployments processed'

		generator = MiGenerator.new(:theoretical)
		tag_positions = {
				train: WorkZone.create_grid_positions_and_rotations(144, 20, nil).first,
				setup: WorkZone.create_grid_positions_and_rotations(4, 20, nil).first,
				test: generator.create_random_positions(144)
		}




		results = []
		deployments.each do |name, deployment|
			r, score = combinational.calculate_score(deployment)
			algorithms, error, limits, generator_data, tdf = calculate_deployment_error(generator, tag_positions, deployment)
			algorithms = clean_algorithms_data(algorithms)
			result = {data: deployment, algorithms: algorithms, error: error, name: name, score: score, generator_data: generator_data, limits: limits, tdf: tdf}
			results.push(result)
		end

		@score_error_correlation = Math.correlation(results.map{|r| r[:error]}, results.map{|r| r[:score]})

		@result = results.sort_by{|d| d[:error]}
	end





	private

	def calculate_deployment_error(generator, tag_positions, antennas)
		reader_power = 20
		frequency = 'multi'
		all_heights = :all_same
		mi_model_type = generator.model
		manager = TagSetsManager.new(
				all_heights,
				:virtual,
				false,
				nil,
				[reader_power],
				generator,
				antennas,
				tag_positions
		)
		tags_input = manager.tags_input[frequency]

		algorithms = {}
		antennas_hash = Hash[antennas.map.with_index{|a,i|[i+1,a]}]

		tri = Algorithm::PointBased::Trilateration.new(reader_power, manager.id, 1,
				tags_input[reader_power], false, false, antennas_hash).
				set_settings(mi_model_type, :rss, Optimization::LeastSquares, :average, :theoretical, 0.0, 2.0, true)
		#tri = Algorithm::PointBased::LinearTrilateration.new(reader_power, manager.id, 1,
		#		tags_input[reader_power], false, false, antennas_hash).
		#		set_settings(mi_model_type, :rss, Optimization::LeastSquares, :average, 0.0, 2.0, :local_maximum)
		algorithms['tri'] = tri.output
		#tri_decision_function = tri.get_decision_function


		algorithms['zonal'] = Algorithm::PointBased::Zonal.new(reader_power, manager.id, 2,
				tags_input[reader_power], false, false, antennas_hash).
				set_settings(mi_model_type, :ellipses, :rss, -99.0).output

		algorithms['knn'] =
				Algorithm::PointBased::Knn.new(reader_power, manager.id, 3, tags_input[reader_power],
						false, false, antennas_hash).
						set_settings(mi_model_type, :rss, Optimization::AngularCosineSimilarity, 8, true, -60.0).output


		algorithms['combo'] = Algorithm::PointBased::Meta::Averager.
			new(algorithms, manager.id, 4, tags_input[20]).
			set_settings(
				false,
				false,
				false,
				false,
				false,
				false,
				:each,
				nil
			).output


		[
				algorithms,
				algorithms['combo'].errors_parameters[0][:total][:mean],
				#[algorithms['combo'].errors_parameters[0][:total][:left_limit], algorithms['combo'].errors_parameters[0][:total][:right_limit]],
				algorithms['combo'].errors_parameters[0][:total][:interval],
				generator_data(manager),
				nil
		]
	end


	def generator_data(manager)
		{
				:rss_errors => manager.generator.rss_errors,
				:rss_rr_correlation => Math.correlation(
						manager.generator.values[:rss],
						manager.generator.values[:rr]
				)
		}
	end



	def draw_deployment
	end
end