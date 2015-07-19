class Deployment::Optimization::SimulatedAnnealing < Deployment::Optimization::Base
	RERUNS = 1
	START_TRYINGS = 1 # 15
	TIME_LIMIT = 11.hours
	ITERATIONS = 6400 # 3300

	def search_for_optimum
		cooling = 0.992

		history = [{score: 0.0, time: Time.now.to_f}]
		global_bests = []
		new_group = Deployment::AntennaGroup.new({}, 0.0)
		RERUNS.times do |i|
			history.push({score: 0.0, time: Time.now.to_f})
			start_time = Time.now
			current_iteration_history = []
			steps_from_best = 0
			temperature = 1.0
			puts i.to_s
			current_group = Deployment::AntennaGroup.new({}, 0.0)
			START_TRYINGS.times do
				grid_antennae, rotations =
						WorkZone.create_grid_positions_and_rotations(@antenna_manager.antennae_count, 65, 0.25*Math::PI)

				grid_antennae = [
						[50, 300], [50, 450], [125, 375], [200, 300], [200, 450],
						[300,50], [300,200], [375,125], [450,50], [450,200],
						[300,300], [300,450], [325,375], [375,325], [450,300], [450,450]
				]
				grid_antennae = grid_antennae.map{|ga| Point.new(ga[0], ga[1])}


				group = Deployment::AntennaGroup.new(@antenna_manager.create_random_group(grid_antennae))
				puts 'created random group'
				group.update_score(@method, true, true, @antenna_manager.obstructions, @antenna_manager.passages)
				puts 'updated score of random group'
				current_group = group if group.score > current_group.score
			end
			best_inside_iteration = current_group.dup
			puts 'starting at ' + current_group.score.to_s
			current_iteration_history.push({score: current_group.score, time: Time.now.to_f})
			#while temperature > 0.00001 do
			i = 0
			#while Time.now < start_time + TIME_LIMIT
			ITERATIONS.times do
				if steps_from_best > 10
					current_group = best_inside_iteration
				end
				puts 'T is ' + temperature.to_s + ' and iteration is ' + i.to_s
				new_group = mutate(current_group)
				probability = Math::E ** ( -(current_group.score - new_group.score) / temperature )
				if new_group.score > current_group.score or rand() < probability
					puts 'changing to ' + new_group.score.to_s
					current_group = new_group
					if best_inside_iteration.score < new_group.score
						best_inside_iteration = new_group.dup
						steps_from_best = 0
					else
						steps_from_best += 1
					end
				end
				puts current_group.score.to_s
				puts 'passed ' + ((Time.now - start_time) / 1.minute.seconds).to_s
				puts ''
				temperature *= cooling
				current_iteration_history.push({score: current_group.score, time: Time.now.to_f})
				i += 1
			end
			puts ''

			history.push current_iteration_history
			global_bests.push current_group.dup
		end

		[history, global_bests]
	end
end