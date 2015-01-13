class Deployment::AntennaGroup
	attr_accessor :data, :score, :results, :rates, :score_map, :need_to_calculate_score
	attr_accessor :history

	def initialize(data, score = nil, results = nil, need_to_calculate_score = true, rates = nil, score_map = nil)
		@score = score
		@results = results
		@data = data # array of Antenna objects
		@need_to_calculate_score = need_to_calculate_score
		@rates = rates
		@score_map = score_map
		@history = {}
	end

	def update_score(method, force_update = true, log = true)
		buffer = nil
		if @need_to_calculate_score or force_update
			results, score, rates, score_map, buffer = method.calculate_score(@data, log)
			@score = score
			@results = results
			@rates = rates
			@score_map = score_map
			@need_to_calculate_score = false
		end
		buffer
	end

	def nearest_groups(antenna_groups, k = 2)
		sorted = antenna_groups.sort_by do |antenna_group|
			distance_to(antenna_group)
		end
		sorted[0...k]
	end

	def distance_to(antenna_group)
		distance = 0.0
		@data.each_with_index do |antenna, i|
			distance += (antenna.coordinates.x - antenna_group.data[i].coordinates.x).abs / WorkZone::WIDTH
			distance += (antenna.coordinates.y - antenna_group.data[i].coordinates.y).abs / WorkZone::HEIGHT
			distance += Math::angle_to_zero_pi_range(
					(antenna.rotation - antenna_group.data[i].rotation).abs / Math::PI
			)
		end
		distance
	end

	def dup
		self.class.new( @data.deep_dup, @score, @results, @need_to_calculate_score, @rates, @score_map )
	end
end