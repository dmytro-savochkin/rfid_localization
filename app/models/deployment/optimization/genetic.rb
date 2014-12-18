require 'mi/base'
require 'algorithm/point_based/zonal/zones_creator'
require 'deployment/method/single/trilateration'
require 'deployment/method/single/fingerprinting'
require 'deployment/method/single/intersectional'

class Deployment::Optimization::Genetic
	SIZE = {
			population: 20,
			elites: 4,
			mutation: 5,
			breeding: 3
	}

	EPOCHS = 3


	def initialize(antenna_manager, method)
		@antenna_manager = antenna_manager
		@method = method
	end

	def search_for_optimum
		if SIZE[:population] < SIZE[:elites] + SIZE[:mutation] + SIZE[:breeding]
			raise Exception.new('population size is too small')
		end
		elites = []
		mutated = []
		bred = []
		EPOCHS.times do |epoch|
			puts ''
			puts '==========================='
			puts 'EPOCH ' + epoch.to_s
			puts '==========================='
			puts ''
			population = create_population(elites, mutated, bred)

			threads = []
			main_buffer = []
			population.each do |antennae_group|
				threads << Thread.new do
					main_buffer << update_antennae_group_score(antennae_group)
				end
			end
			threads.map{|t| t.value}

			main_buffer.each do |buffer|
				buffer.each{|row| puts row.to_s} if buffer
			end

			puts elites.map{|e| e[:score]}.to_s
			puts mutated.map{|e| e[:score]}.to_s
			puts bred.map{|e| e[:score]}.to_s

			sorted_population = population.sort_by{|ag| ag[:score]}
			elites = sorted_population[-SIZE[:elites]..-1]

			if epoch < EPOCHS - 1
				#puts 'we are mutating ' + sorted_population[-SIZE[:mutation]..-1].map{|ag| ag[:data].map{|a| [a.number, a.coordinates.short_to_s]}}.to_s
				mutated = mutate( sorted_population[-SIZE[:mutation]..-1] )
				bred = breed( sorted_population[-SIZE[:breeding]*2..-1] )
				#puts 'we are getting ' + mutated.map{|ag| ag[:data].map{|a| [a.number, a.coordinates.short_to_s]}}.to_s
				#puts 'we were left with ' + sorted_population[-SIZE[:mutation]..-1].map{|ag| ag[:data].map{|a| [a.number, a.coordinates.short_to_s]}}.to_s
			end




			puts sorted_population.map{|e| e[:score]}.to_s
			puts elites.map{|e| e[:score]}.to_s
			puts mutated.map{|e| e[:score]}.to_s
			puts bred.map{|e| e[:score]}.to_s
			puts "Best score for #{epoch} is #{elites[-1][:score]}"
			puts '...'
			puts ''
		end
		elites[-1]
	end









	private

	def update_antennae_group_score(antennae_group, log = true)
		buffer = nil
		if antennae_group[:need_to_calculate_score]
			results, score, rates, buffer = @method.calculate_score(antennae_group[:data], log)
			antennae_group[:score] = score
			antennae_group[:results] = results
			antennae_group[:rates] = rates
			antennae_group[:need_to_calculate_score] = false
		end
		buffer
	end

	def create_population(elites, mutated, bred)
		population = []
		(SIZE[:population] - elites.length - mutated.length - bred.length).times do
			population.push(create_antennae_group_hash(@antenna_manager.create_random_group))
		end
		population + elites + mutated + bred
	end




	def mutate(population)
		mutated_species = []
		population.each do |antennae_group|
			current_mutated = create_antennae_group_hash( antennae_group[:data].map{|a| a.dup} )

			current_mutated[:data].each do |antenna|
				if rand < 0.5
					@antenna_manager.shift_antenna(antenna, current_mutated[:data] - [antenna])
				end
				if rand < 0.5
					@antenna_manager.rotate_antenna(antenna)
				end
			end
			update_antennae_group_score(current_mutated)
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
			update_antennae_group_score(current_bred, false)
			#puts ''
			#puts current_bred[:score].to_s
			#puts current_bred[:data].map{|a| [a.coordinates.to_round_s, a.rotation]}.to_s
			#puts ''
			bred_species.push current_bred
		end
		bred_species
	end
	def breed_two_species(specie1, specie2, type = :nearest_one)
		bred = specie1[:data].dup
		if type == :random_one
			i = rand(specie1[:data].length - 1)
			antenna1 = specie1[:data][i]
			antenna2 = specie2[:data][i]
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
			i = specie1[:data].each_with_index.sort_by{|a, i| Point.distance(random_point, a.coordinates)}.first[1]
			nearest_antenna2 = specie2[:data].sort_by{|a| Point.distance(random_point, a.coordinates)}.first
			bred[i] = nearest_antenna2.dup
		end

		create_antennae_group_hash(bred)
	end



	def create_antennae_group_hash(data)
		{
				score: nil,
				results: nil,
				data: data,
				need_to_calculate_score: true
		}
	end
end