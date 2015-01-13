class WorkZone
  ROOM_HEIGHT = 260

  WIDTH = 500
  HEIGHT = 500
	CENTER_POINT = Point.new(WIDTH.to_f/2, HEIGHT.to_f/2)

	attr_accessor :width, :height, :antennae, :reader_power

  def initialize(antennae, reader_power = nil)
    @reader_power = reader_power
    @width = WIDTH
    @height = HEIGHT
		if antennae.is_a?(Array)
			@antennae = Hash[ antennae.map.with_index{|a,i|[i,a]} ]
		elsif antennae.is_a?(Hash)
			@antennae = antennae
		else
			raise ArgumentError.new('Wrong type for antennae argument')
		end
	end




	def self.create_default_antennae(antennae_count = 16, antennae_shift = 70, zone_size = Zone::POWERS_TO_SIZES[reader_power], big_zone_size = zone_size.map{|e|1.5*e}, rotation = Math::PI / 4, type = :grid, params = {})
		antennae = {}
		if type == :grid
			positions, rotations =
					WorkZone.create_grid_positions_and_rotations(antennae_count, antennae_shift, rotation)
		elsif type == :triangular
			positions, rotations =
					WorkZone.create_triangular_positions_and_rotations(antennae_count, antennae_shift, rotation)
		elsif type == :triangular2
			positions, rotations =
					WorkZone.create_triangular2_positions_and_rotations(antennae_count, antennae_shift, rotation)
		elsif type == :square
			positions, rotations =
					WorkZone.create_square_positions_and_rotations(antennae_count, antennae_shift, rotation, params)
		elsif type == :square2
			positions, rotations =
					WorkZone.create_square2_positions_and_rotations(antennae_count, antennae_shift, rotation, params)
		elsif type == :round
			positions, rotations =
					WorkZone.create_round_positions_and_rotations(antennae_count, antennae_shift, rotation, params)
		else
			raise StandardError.new("Wrong type #{type}")
		end

		positions.each_with_index do |current_position, index|
			current_rotation = rotations[index]
			antennae[index + 1] = Antenna.new(index + 1, zone_size, big_zone_size, current_position, current_rotation)
		end
		antennae
	end

	def self.create_default_round_antennae()
	end






	def self.create_random_positions(count, shift)
		count.times.map do
			Point.new(rand((shift..WorkZone::WIDTH-shift)), rand((shift..WorkZone::HEIGHT-shift)))
		end
	end

	def self.create_grid_positions_and_rotations(count, shift, rotation)
		start_point, end_point = self.create_start_and_end_points(shift)
		center = Point.new(WIDTH.to_f / 2, HEIGHT.to_f / 2)

		count_in_row = Math.sqrt(count.to_f).floor
		step = (end_point.x - start_point.x) / (count_in_row - 1)
		step = 0.0 if count_in_row <= 1

		positions = []
		rotations = []

		count_in_row.times do |x|
			count_in_row.times do |y|
				position = Point.new(start_point.x + x * step, start_point.y + y * step)
				positions.push( position )
				rotations.push( rotation == :to_center ? position.angle_to_point(center) : rotation )
			end
		end

		[positions, rotations]
	end

	# count = 5, 13, 25, ...
	def self.create_triangular_positions_and_rotations(count, shift, rotation)
		raise StandardError.new('Wrong antennae count. Should be 5 or more.') if count < 5
		center = Point.new(WIDTH.to_f / 2, HEIGHT.to_f / 2)
		start_point, end_point = self.create_start_and_end_points(shift)
		positions = []
		rotations = []

		corrected_count = 5
		sides = 1
		while true
			break if corrected_count >= count
			sides.times do
				2.times do
					corrected_count += 2
				end
			end
			corrected_count += 2 # exclude two bottom right positions
			corrected_count += 1 # exclude bottom left position
			corrected_count += 1 # exclude upper right position
			sides += 1
		end

		count_in_main_row = sides + 1
		step = ((end_point.x - start_point.x) / (count_in_main_row - 1)).to_f
		count_in_main_row.times do |x|
			count_in_main_row.times do |y|
				position = Point.new(start_point.x + x * step, start_point.y + y * step)
				positions.push( position )
				rotations.push( rotation == :to_center ? position.angle_to_point(center) : rotation )
			end
		end

		secondary_start_point = start_point.dup
		secondary_start_point.shift(step / 2, step / 2)
		count_in_secondary_row = sides
		count_in_secondary_row.times do |x|
			count_in_secondary_row.times do |y|
				position = Point.new(secondary_start_point.x + x * step, secondary_start_point.y + y * step)
				positions.push( position )
				rotations.push( rotation == :to_center ? position.angle_to_point(center) : rotation )
			end
		end

		[positions, rotations]
	end


	# count = 4, 9, 16, 25, ...
	def self.create_triangular2_positions_and_rotations(count, shift, rotation)
		raise StandardError.new('Wrong antennae count. Should be 4 or more.') if count < 4
		center = Point.new(WIDTH.to_f / 2, HEIGHT.to_f / 2)
		start_point, end_point = self.create_start_and_end_points(shift)
		positions = []
		rotations = []

		corrected_count = 4
		while true
			break if corrected_count >= count
			corrected_count = (Math.sqrt(corrected_count) + 1) ** 2
		end

		count_in_main_row = Math.sqrt(corrected_count).to_i
		x_step = ((end_point.x - start_point.x + shift / 2) / (count_in_main_row - 1)).to_f
		y_step = ((end_point.y - start_point.y) / (count_in_main_row - 1)).to_f
		count_in_main_row.times do |x|
			count_in_main_row.times do |y|
				x_shift = ((y.to_f % 2).to_f != 0.0 ? -shift.to_f / 2 : 0.0)
				position = Point.new(start_point.x + x * x_step + x_shift, start_point.y + y * y_step)
				positions.push( position )
				rotations.push( rotation == :to_center ? position.angle_to_point(center) : rotation )
			end
		end

		[positions, rotations]
	end



	# count = 4(5), 8(9), 12(13), 16(17)
	def self.create_square_positions_and_rotations(count, shift, rotation, params)
		if (count < 4 and params[:at_center]) or (count < 5 and !params[:at_center])
			raise StandardError.new('Wrong antennae count. Should be 4(5) or more.')
		end

		center = Point.new(WIDTH.to_f / 2, HEIGHT.to_f / 2)
		start_point, end_point = self.create_start_and_end_points(shift)
		positions = []
		rotations = []

		corrected_count = (params[:at_center] ? 5 : 4)
		count_in_row = 2
		while true
			break if corrected_count >= count
			count_in_row += 1
			corrected_count += 4
		end

		push_position_and_rotation = lambda do |x, y|
			position = Point.new(x, y)
			positions.push(position)
			rotations.push(rotation == :to_center ? position.angle_to_point(center) : rotation)
		end

		step = ((end_point.x - start_point.x) / (count_in_row - 1)).to_f
		count_in_row.times do |x_index|
			x = start_point.x + x_index * step
			[start_point.y, end_point.y].each do |y|
				push_position_and_rotation.call(x, y)
			end
		end

		if count_in_row > 2
			(count_in_row - 2).times do |y_index|
				y = start_point.y + (y_index + 1) * step
				[start_point.x, end_point.x].each do |x|
					push_position_and_rotation.call(x, y)
				end
			end
		end

		if params[:at_center]
			positions.push( Point.new(WIDTH.to_f / 2, HEIGHT.to_f / 2) )
			rotations.push( rotation == :to_center ? 0.0 : rotation )
		end

		[positions, rotations]
	end




	# count >= 4
	def self.create_square2_positions_and_rotations(count, shift, rotation, params)
		if count < 4
			raise StandardError.new('Wrong antennae count. Should be 4 or more.')
		end

		center = Point.new(WIDTH.to_f / 2, HEIGHT.to_f / 2)
		start_point, end_point = self.create_start_and_end_points(shift)
		positions = []
		rotations = []

		directions_queue = [:right, :up, :left, :down]
		perimeter = (WorkZone::WIDTH.to_f - shift.to_f * 2) * 4
		corrected_count = (params[:at_center] ? count - 1 : count)
		step = perimeter / corrected_count

		corners = {
				ne: Point.new(WorkZone::WIDTH-shift, WorkZone::HEIGHT-shift),
				se: Point.new(WorkZone::WIDTH-shift, shift),
				sw: Point.new(shift, shift),
				nw: Point.new(shift, WorkZone::HEIGHT-shift)
		}

		current_point = start_point.dup
		positions.push current_point.dup
		rotations.push(rotation == :to_center ? current_point.angle_to_point(center) : rotation)
		current_direction = directions_queue.shift
		while positions.length < corrected_count
			case current_direction
				when :right
					if current_point.x + step <= corners[:se].x
						current_point.shift(step, 0)
					else
						current_point.y = corners[:se].y + (step - (corners[:se].x - current_point.x))
						current_point.x = corners[:se].x
						current_direction = directions_queue.shift
					end
				when :down
					if current_point.y - step >= corners[:sw].y
						current_point.shift(0, -step)
					else
						current_point.x = corners[:sw].x + (step - (current_point.y - corners[:sw].y))
						current_point.y = corners[:sw].y
						current_direction = directions_queue.shift
					end
				when :left
					if current_point.x - step >= corners[:nw].x
						current_point.shift(-step, 0)
					else
						current_point.y = corners[:nw].y - (step - (current_point.x - corners[:nw].x))
						current_point.x = corners[:nw].x
						current_direction = directions_queue.shift
					end
				when :up
					if current_point.y + step <= corners[:ne].y
						current_point.shift(0, step)
					else
						current_point.x = corners[:ne].x - (step - (corners[:ne].y - current_point.y))
						current_point.y = corners[:ne].y
						current_direction = directions_queue.shift
					end
				else
					raise Exception.new('WTF?')
			end
			positions.push current_point.dup
			rotations.push(rotation == :to_center ? current_point.angle_to_point(center) : rotation)
		end

		if params[:at_center]
			positions.push( Point.new(WIDTH.to_f / 2, HEIGHT.to_f / 2) )
			rotations.push( rotation == :to_center ? 0.0 : rotation )
		end

		[positions, rotations]
	end




	def self.create_round_positions_and_rotations(count, shift, rotation, params)
		raise StandardError.new('Wrong antennae count. Should be 4 or more.') if count < 4
		center = Point.new(WIDTH.to_f / 2, HEIGHT.to_f / 2)
		angle_step = 2 * Math::PI / (params[:at_center] ? count - 1 : count)

		radius = Point.distance(Point.new(0, WorkZone::HEIGHT/2), center) - shift

		positions = []
		rotations = []

		if params[:at_center]
			positions.push(center)
			rotations.push(rotation == :to_center ? 0.0 : rotation)
		end

		(params[:at_center] ? count - 1 : count).times do |i|
			angle = i * angle_step
			x = radius.to_f * Math.cos(angle)
			y = radius.to_f * Math.sin(angle)
			position = Point.new(x + center.x, y + center.y)
			positions.push(position)
			rotations.push(rotation == :to_center ? angle : rotation)
		end

		[positions, rotations]
	end




	private

	def self.create_start_and_end_points(shift)
		start_point = Point.new(shift, shift)
		end_point = Point.new(WIDTH.to_f - shift, HEIGHT.to_f - shift)
		[start_point, end_point]
	end
end