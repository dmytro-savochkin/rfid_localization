class Deployment::Optimization::Base
	def initialize(antenna_manager, method)
		@antenna_manager = antenna_manager
		@method = method
	end


	private

	def mutate(solution)
		#current_mutated = Deployment::AntennaGroup.new( group[:data].map{|a| a.dup} )
		mutated = solution.dup
		probability = [1.0 / mutated.data.length, 0.5].max
		mutated.data.each do |antenna|
			if rand < probability
				@antenna_manager.shift_antenna(antenna, mutated.data - [antenna])
			end
			if rand < probability
				@antenna_manager.rotate_antenna(antenna)
			end
		end
		mutated.update_score(@method)
		mutated
	end
end
