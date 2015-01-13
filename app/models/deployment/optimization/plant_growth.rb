class Deployment::Optimization::PlantGrowth < Deployment::Optimization::Base
	START_TRYINGS = 20
	BRANCHES = 5
	RERUNS = 1
	TIME_LIMIT = 6.hours
	ITERATIONS = 400

	def search_for_optimum
		global_history = [{score: 0.0, time: Time.now.to_f}]
		global_bests = []

		RERUNS.times do |rerun|
			start_time = Time.now
			puts 'RERUN ' + rerun.to_s
			puts '====================='

			history = [{score: 0.0, time: Time.now.to_f}]
			start_solution = Deployment::AntennaGroup.new({}, 0.0)
			START_TRYINGS.times do
				solution = Deployment::AntennaGroup.new(@antenna_manager.create_random_group)
				solution.update_score(@method)
				start_solution = solution if solution.score > start_solution.score
			end
			history.push({score: start_solution.score, time: Time.now.to_f})

			leafs = [start_solution]
			i = 0
			#while Time.now < start_time + TIME_LIMIT
			ITERATIONS.times do
				puts 'iteration: ' + i.to_s

				current_solution = choose_leaf_to_mutate_from(leafs)
				puts 'Leafs: ' + leafs.map{|l| l.score}.to_s
				puts 'score for current_solution is ' + current_solution.score.to_s

				BRANCHES.times do
					new_solution = mutate(current_solution)
					new_solution.update_score(@method)
					buffer = 'new. score is ' + new_solution.score.to_s
					if new_solution.score > current_solution.score
						buffer += '. accepting.'
						leafs.push new_solution
						leafs.delete(current_solution)
					end
					puts buffer.to_s
				end


				if leafs.length > 5
					leafs = leafs.sort_by{|l| l.score}[-5..-1]
				end

				best = leafs.sort_by{|l| l.score}.last
				history.push({score: best.score, time: Time.now.to_f})
				puts 'best is ' + best.score.to_s
				puts 'passed ' + ((Time.now - start_time) / 1.minute.seconds).to_s
				puts ''
				i += 1
			end

			global_history.push(history)
			global_bests.push(leafs.sort_by{|s| s.score}.last)
		end

		[global_history, global_bests]
	end




	private


	def choose_leaf_to_mutate_from(leafs)
		shift = 0.7
		leafs_min_score = leafs.map{|leaf| leaf.score}.min
		total_leafs_score = leafs.map{|leaf| leaf.score - shift*leafs_min_score}.sum

		random_value = rand()
		return leafs.last if random_value == 1.0

		probabilities_summed_up = 0.0
		leafs.each do |leaf|
			probability = (leaf.score - shift*leafs_min_score) / total_leafs_score
			limits = probabilities_summed_up...(probabilities_summed_up+probability)
			if limits.include? random_value
				return leaf
			end
			probabilities_summed_up += probability
		end

		raise Exception.new('WTF! A leaf is not chosen. ' + leafs.to_s + ' ' + probabilities_summed_up.to_s + ' ' + limits.to_s)
	end
end