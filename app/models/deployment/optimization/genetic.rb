class Deployment::Optimization::Genetic < Deployment::Optimization::Base
	SIZE = {
			population: 20,
			elites: 4,
			mutation: 5,
			breeding: 1
	}
	#SIZE = {
	#		population: 5,
	#		elites: 1,
	#		mutation: 1,
	#		breeding: 1
	#}
	TIME_LIMIT = 6.hours
	ITERATIONS = 200

	#EPOCHS = 100
	#SIZE = {
	#		population: 10,
	#		elites: 2,
	#		mutation: 2,
	#		breeding: 2
	#}
	#EPOCHS = 2


	def search_for_optimum
		if SIZE[:population] < SIZE[:elites] + SIZE[:mutation] + SIZE[:breeding]
			raise Exception.new('population size is too small')
		end
		start_time = Time.now
		elites = []
		mutated = []
		bred = []
		history = [{score: 0.0, time: Time.now.to_f}]
		epoch = 0
		#while Time.now < start_time + TIME_LIMIT
		ITERATIONS.times do
			puts ''
			puts '==========================='
			puts 'EPOCH ' + epoch.to_s
			puts '==========================='
			puts ''
			population = create_population(elites, mutated, bred)

			threads = []
			main_buffer = []
			population.each do |antennae_group|
				#threads << Thread.new do
					main_buffer << antennae_group.update_score(@method, false)
				#end
			end
			#threads.map{|t| t.value}

			main_buffer.each do |buffer|
				buffer.each{|row| puts row.to_s} if buffer
			end

			puts elites.map{|e| e.score}.to_s
			puts mutated.map{|e| e.score}.to_s
			puts bred.map{|e| e.score}.to_s

			sorted_population = population.sort_by{|ag| ag.score}
			elites = sorted_population[-SIZE[:elites]..-1]

			#puts 'we are mutating ' + sorted_population[-SIZE[:mutation]..-1].map{|ag| ag.data.map{|a| [a.number, a.coordinates.short_to_s]}}.to_s
			mutated = mutate( sorted_population[-SIZE[:mutation]..-1] )
			bred = breed( sorted_population[-SIZE[:breeding]*2..-1] )
			#puts 'we are getting ' + mutated.map{|ag| ag.data.map{|a| [a.number, a.coordinates.short_to_s]}}.to_s
			#puts 'we were left with ' + sorted_population[-SIZE[:mutation]..-1].map{|ag| ag.data.map{|a| [a.number, a.coordinates.short_to_s]}}.to_s
			history.push({score: elites[-1].score, time: Time.now.to_f})

			puts sorted_population.map{|e| e.score}.to_s
			puts elites.map{|e| e.score}.to_s
			puts mutated.map{|e| e.score}.to_s
			puts bred.map{|e| e.score}.to_s
			puts "Best score for #{epoch} is #{elites[-1].score}"
			puts 'passed ' + ((Time.now - start_time) / 1.minute.seconds).to_s
			puts '...'
			puts ''
			epoch += 1
		end

		[history, [elites[-1]]]
	end









	private

	def create_population(elites, mutated, bred)
		population = []
		(SIZE[:population] - elites.length - mutated.length - bred.length).times do
			population.push(Deployment::AntennaGroup.new(@antenna_manager.create_random_group))
		end
		population + elites + mutated + bred
	end




	def mutate(population)
		mutated_species = []
		population.each do |antennae_group|
			#current_mutated = Deployment::AntennaGroup.new( antennae_group[:data].map{|a| a.dup} )
			current_mutated = antennae_group.dup

			current_mutated.data.each do |antenna|
				if rand < 0.5
					@antenna_manager.shift_antenna(antenna, current_mutated.data - [antenna])
				end
				if rand < 0.5
					@antenna_manager.rotate_antenna(antenna)
				end
			end
			current_mutated.update_score(@method)
			mutated_species.push current_mutated
		end
		mutated_species
	end


	def breed(population)
		bred_species = []

		combinations = (0...population.length).to_a.combination(2).to_a.shuffle
		SIZE[:breeding].times do
			combination = combinations.shift
			#puts population[combination.first][:score].to_s
			#puts population[combination.first][:data].map{|a| [a.coordinates.to_round_s, a.rotation]}.to_s
			#puts population[combination.last][:score].to_s
			#puts population[combination.last][:data].map{|a| [a.coordinates.to_round_s, a.rotation]}.to_s
			current_bred = breed_two_species(population[combination.first], population[combination.last])
			current_bred.update_score(@method, true, false)
			#puts ''
			#puts current_bred[:score].to_s
			#puts current_bred[:data].map{|a| [a.coordinates.to_round_s, a.rotation]}.to_s
			#puts ''
			bred_species.push current_bred
		end
		bred_species
	end
	def breed_two_species(specie1, specie2, type = :nearest_one)
		bred = specie1.data.dup
		if type == :random_one
			i = rand(specie1.data.length - 1)
			antenna1 = specie1.data[i]
			antenna2 = specie2.data[i]
			coverage_zone = [
					[antenna1.coverage_zone_width, antenna2.coverage_zone_width].sample,
					[antenna1.coverage_zone_height, antenna2.coverage_zone_height].sample
			]
			big_coverage_zone = [
					[antenna1.big_coverage_zone_width, antenna2.big_coverage_zone_width].sample,
					[antenna1.big_coverage_zone_height, antenna2.big_coverage_zone_height].sample
			]
			coordinates = Point.center_of_points([antenna1.coordinates, antenna2.coordinates])
			rotation = rand(antenna1.rotation..antenna2.rotation)
			bred[i] = Antenna.new(
					i,
					coverage_zone,
					big_coverage_zone,
					coordinates,
					rotation
			)
		else
			random_point = Point.new(rand(WorkZone::WIDTH), rand(WorkZone::HEIGHT))
			i = specie1.data.each_with_index.sort_by{|a, i| Point.distance(random_point, a.coordinates)}.first[1]
			nearest_antenna2 = specie2.data.sort_by{|a| Point.distance(random_point, a.coordinates)}.first
			bred[i] = nearest_antenna2.dup
		end

		Deployment::AntennaGroup.new(bred)
	end
end