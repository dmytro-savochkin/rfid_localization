class Deployment::AntennaManager
	attr_reader :antennae_count, :obstructions, :passages

	COVERAGE_ZONE_SIZES = [
			{small: [250,160], big: [300,190]}
			#{small: [250,160], big: [250,160]}
			#{small: [160, 180], big: [220, 280]}
			#{small: [200,230], big: [270,340]}
	]
	ROTATIONS = [0.0, 0.25*Math::PI, 0.5*Math::PI, 0.75*Math::PI]
	SHIFT = 30.0
	MARGIN = 50.0
	REQUIRED_COVERAGE_RATE = 0.85 # 0.85


	def initialize(antennae_count, obstructions = [], passages = [])
		@obstructions = obstructions
		@passages = passages
		@antennae_count = antennae_count
		@antenna_shift_normal_distribution = Rubystats::NormalDistribution.new(0.0, 4.0) # sigma = 4 cm
		@antenna_rotate_normal_distribution = Rubystats::NormalDistribution.new(0.0, 0.05 * Math::PI)
		#@point_c_code = Point::CCode.new
		@point_c_code = nil
	end

	def create_random_group(positions = nil)
		coverage_rate = 0.0

		until coverage_rate >= REQUIRED_COVERAGE_RATE
			antennae = []
			quadrant = 1
			antennas_in_current_quadrant = 0
			antennas_per_quadrant = (@antennae_count.to_f/4).round
			@antennae_count.times do |i|
				if antennas_in_current_quadrant >= antennas_per_quadrant
					antennas_in_current_quadrant = 0
					quadrant += 1
				end

				zone_size = COVERAGE_ZONE_SIZES[rand(0...COVERAGE_ZONE_SIZES.length)]
				rotation = ROTATIONS[rand(0...ROTATIONS.length)]
				if positions.nil?
					coordinates = generate_antenna_position(antennae, quadrant)
				else
					coordinates = positions[i]
				end
				antenna = Antenna.new(i+1, zone_size[:small], zone_size[:big], coordinates, rotation)
				antennae.push antenna

				antennas_in_current_quadrant += 1
			end
			coverage_rate = calculate_coverage_rate(antennae)
			puts 'it is ' + coverage_rate.to_s
		end

		antennae
	end


	def shift_antenna(antenna, other_antennae)
		10.times do
			ax = antenna.coordinates.x + @antenna_shift_normal_distribution.rng.to_f
			ay = antenna.coordinates.y + @antenna_shift_normal_distribution.rng.to_f
			possible_antenna_position = Point.new(ax, ay)

			not_possible_position = false
			other_antennae.each do |other_antenna|
				inside_obstructions = false
				@obstructions.each do |obstruction|
					if obstruction.point_inside?(possible_antenna_position)
						inside_obstructions = true
						break
					end
				end

				if inside_obstructions or Point.distance(possible_antenna_position, other_antenna.coordinates, @point_c_code) < MARGIN
					not_possible_position = true
					break
				end
			end

			unless not_possible_position
				antenna.coordinates.x = ax
				antenna.coordinates.y = ay
				break
			end
		end
	end
	def rotate_antenna(antenna)
		antenna.rotation += @antenna_rotate_normal_distribution.rng.to_f
	end




	private

	def calculate_coverage_rate(antennae)
		step = 5

		points_covered = 0
		work_zone = WorkZone.new(antennae, nil, @obstructions, @passages)
		total_work_zone_area =
				((work_zone.width.to_f / step) + 1) ** 2 -
						@obstructions.map{|o|o.full_area/step**2}.sum.to_f -
						@passages.map{|p|p.full_area/step**2}.sum.to_f
		(0.0..work_zone.width.to_f).step(step) do |x|
			(0.0..work_zone.height.to_f).step(step) do |y|
				point = Point.new(x, y)
				next if work_zone.inside_obstructions?(point) or work_zone.inside_passages?(point)
				antennae.each do |antenna|
					if MI::A.point_in_ellipse?(point, antenna, [antenna.coverage_zone_width, antenna.coverage_zone_height])
						points_covered += 1
						break
					end
				end
			end
		end

		points_covered / total_work_zone_area
	end

	def generate_antenna_position(antennae, quadrant = nil)
		work_zone = WorkZone.new(antennae, nil, @obstructions, @passages)
		while true
			limits = get_limits(quadrant)
			position = Point.new(rand(limits.first), rand(limits.last))
			next if work_zone.inside_obstructions?(position)
			antennas_are_near = false
			antennae.each do |antenna|
				if Point.distance(antenna.coordinates, position) < MARGIN
					antennas_are_near = true
					break
				end
			end
			next if antennas_are_near
			return position
		end
	end

	def get_limits(quadrant = nil)
		default = [SHIFT..WorkZone::WIDTH.to_f - SHIFT, SHIFT..WorkZone::HEIGHT.to_f - SHIFT]
		if quadrant
			center = Point.new(WorkZone::WIDTH.to_f/2, WorkZone::HEIGHT.to_f/2)
			case quadrant
			when 1
				[center.x..WorkZone::WIDTH.to_f - SHIFT, center.y..WorkZone::HEIGHT.to_f - SHIFT]
			when 2
				[SHIFT..center.x, center.y..WorkZone::HEIGHT.to_f - SHIFT]
			when 3
				[SHIFT..center.x, SHIFT..center.y]
			when 4
				[center.x..WorkZone::WIDTH.to_f - SHIFT, SHIFT..center.y]
			else
				default
			end
		else
			default
		end
	end
end