class Deployment::AntennaManager
	attr_reader :antennae_count

	COVERAGE_ZONE_SIZES = [
			#{small: [160, 180], big: [220, 280]}
			{small: [250,160], big: [300,190]}
			#{small: [200,230], big: [270,340]}
	]
	ROTATIONS = [0.0, 0.25*Math::PI, 0.5*Math::PI, 0.75*Math::PI]
	SHIFT = 50.0
	MARGIN = 50.0
	REQUIRED_COVERAGE_RATE = 0.85


	def initialize(antennae_count)
		@antennae_count = antennae_count
		@antenna_shift_normal_distribution = Rubystats::NormalDistribution.new(0.0, 4.0) # sigma = 4 cm
		@antenna_rotate_normal_distribution = Rubystats::NormalDistribution.new(0.0, 0.05 * Math::PI)
		@point_c_code = Point::CCode.new
	end

	def create_random_group
		coverage_rate = 0.0

		until coverage_rate >= REQUIRED_COVERAGE_RATE
			antennae = []
			@antennae_count.times do |i|
				zone_size = COVERAGE_ZONE_SIZES[rand(0...COVERAGE_ZONE_SIZES.length)]
				rotation = ROTATIONS[rand(0...ROTATIONS.length)]
				coordinates = generate_antenna_position(antennae)
				antenna = Antenna.new(i, zone_size[:small], zone_size[:big], coordinates, rotation)
				antennae.push antenna
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

			antennas_are_near = false
			other_antennae.each do |other_antenna|
				if Point.distance(possible_antenna_position, other_antenna.coordinates, @point_c_code) < MARGIN
					antennas_are_near = true
					break
				end
			end

			unless antennas_are_near
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
		work_zone = WorkZone.new(antennae, nil)
		total_work_zone_area = ((work_zone.width.to_f / step) + 1) ** 2
		(0.0..work_zone.width.to_f).step(step) do |x|
			(0.0..work_zone.height.to_f).step(step) do |y|
				point = Point.new(x, y)
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

	def generate_antenna_position(antennae)
		while true
			position = Point.new(rand(SHIFT..WorkZone::WIDTH.to_f - SHIFT), rand(SHIFT..WorkZone::HEIGHT.to_f - SHIFT))
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
end