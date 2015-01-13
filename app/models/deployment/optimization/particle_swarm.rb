class Deployment::Optimization::ParticleSwarm < Deployment::Optimization::Base
	PARTICLES = 12
	TIME_LIMIT = 20.hours
	RERUNS = 1
	ITERATIONS = 265

	def search_for_optimum
		global_history = [{score: 0.0, time: Time.now.to_f}]
		global_bests = []

		RERUNS.times do |rerun|
			start_time = Time.now
			puts 'RERUN ' + rerun.to_s
			puts '====================='

			initialize_params
			particles, particle_speeds = create_particles_and_their_speeds
			best = nil
			history = [{score: 0.0, time: Time.now.to_f}]

			particles.each do |particle|
				particle.history[:local] = particle.dup
				if best.nil? or best.score < particle.score
					best = particle.dup
				end
			end

			update_neighborhood_bests(particles)

			i = 0
			while Time.now < start_time + TIME_LIMIT
			#ITERATIONS.times do
				puts 'iteration: ' + i.to_s
				particles.each_with_index do |particle, particle_index|
					speed = calculate_new_speed(particle, particle_speeds[particle_index])
					move_particle(particle, speed)
					particle.update_score(@method)
					particle_speeds[particle_index] = speed
					puts 'particle #' + particle_index.to_s + ' score is ' + particle.score.to_s

					if particle.history[:local].nil? or particle.history[:local].score < particle.score
						particle.history[:local] = particle.dup
					end
					if best.nil? or best.score < particle.score
						best = particle.dup
					end
				end

				update_neighborhood_bests(particles)

				puts 'global best so far is ' + best.score.to_s
				#puts 'speed is ' + particle_speeds.to_yaml
				#puts 'particles are ' + particles.map{|p| p.data.map{|a| [a.coordinates.x.round(2),a.coordinates.y.round(2), a.rotation.round(2)]}}.to_s
				puts 'local     are ' + particles.map{|p| p.history[:local].score}.to_s
				puts 'neighb    are ' + particles.map{|p| p.history[:neighborhood].score}.to_s


				@inertia_weight -= @inertia_weight_step if @inertia_weight > @min_inertia_weight
				@max_speed.keys.each do |k|
					@max_speed[k] -= @max_speed_step[k] if @max_speed[k] > @end_max_speed[k]
				end
				history.push({score: best.score, time: Time.now.to_f})
				puts @max_speed.to_s
				puts @inertia_weight.to_s
				puts 'passed ' + ((Time.now - start_time) / 1.minute.seconds).to_s
				puts ''
				i += 1
			end

			global_history.push(history)
			global_bests.push(best)
		end


		[global_history, global_bests]
	end




	private

	def initialize_params
		iterations = 180 # 100 -> 2.5 hours with 10 particles
		@max_speed = {x: 0.4*WorkZone::WIDTH, y: 0.4*WorkZone::HEIGHT, rotation: 0.4*Math::PI}
		@end_max_speed = {x: 0.2*WorkZone::WIDTH, y: 0.2*WorkZone::HEIGHT, rotation: 0.2*Math::PI}
		@max_speed_step = Hash[ @max_speed.map{|k,v| [k, (v - @end_max_speed[k]) / iterations]} ]

		@inertia_weight = 0.9
		@min_inertia_weight = 0.2
		@inertia_weight_step = (@inertia_weight - @min_inertia_weight) / iterations
	end


	def update_neighborhood_bests(particles)
		particles.each do |particle|
			nearest_neighbors = particle.nearest_groups(particles, 4)
			nearest_neighbors_best_locals = nearest_neighbors.map{|p| p.history[:local]}
			neighborhood_best_local = nearest_neighbors_best_locals.sort_by{|p| p.score}.last
			particle.history[:neighborhood] = neighborhood_best_local.dup
		end
	end


	def calculate_new_speed(particle, speed)
		new_speed = {}
		speed.each do |antenna_number, antenna_speed|
			new_speed[antenna_number] = {x: 0.0, y: 0.0, rotation: 0.0}
			[:x, :y, :rotation].each do |element_name|
				inertia = @inertia_weight * antenna_speed[element_name]
				new_speed[antenna_number][element_name] = inertia
				if particle.history[:local] and particle.history[:neighborhood]
					if element_name == :rotation
						value_of_current_best = Math::angle_to_zero_pi_range(particle.history[:local].data[antenna_number].rotation)
						value_of_global_best = Math::angle_to_zero_pi_range(particle.history[:neighborhood].data[antenna_number].rotation)
						value_of_particle = Math::angle_to_zero_pi_range(particle.data[antenna_number].rotation)
					else
						value_of_current_best = particle.history[:local].data[antenna_number].coordinates.send(element_name)
						value_of_global_best = particle.history[:neighborhood].data[antenna_number].coordinates.send(element_name)
						value_of_particle = particle.data[antenna_number].coordinates.send(element_name)
					end
					local_best_experience = 2.0 * rand() * (value_of_current_best - value_of_particle)
					global_best_experience = 2.0 * rand() * (value_of_global_best - value_of_particle)
					new_speed[antenna_number][element_name] += local_best_experience + global_best_experience
				end

				if element_name != :rotation
					if new_speed[antenna_number][element_name] > @max_speed[element_name]
						new_speed[antenna_number][element_name] = @max_speed[element_name]
					elsif new_speed[antenna_number][element_name] < -@max_speed[element_name]
						new_speed[antenna_number][element_name] = -@max_speed[element_name]
					end
				end
			end

			# maybe we need this angle restriction? don't know
			# new_speed[antenna_number][:rotation] = Math::angle_to_zero_pi_range(new_speed[antenna_number][:rotation])
		end

		new_speed
	end


	def move_particle(particle, speed)
		speed.each do |antenna_number, antenna_speed|
			[:x, :y, :rotation].each do |element_name|
				if element_name == :rotation
					particle.data[antenna_number].rotation += antenna_speed[:rotation]
				else
					particle.data[antenna_number].coordinates.send(
							element_name.to_s + '=',
							particle.data[antenna_number].coordinates.send(element_name) + antenna_speed[element_name]
					)
				end
			end

			particle_antenna_x_position = particle.data[antenna_number].coordinates.x
			if particle_antenna_x_position > WorkZone::WIDTH or particle_antenna_x_position < 0.0
				speed[antenna_number][:x] *= -1.0
				if particle_antenna_x_position > WorkZone::WIDTH
					particle.data[antenna_number].coordinates.x = WorkZone::WIDTH - (particle_antenna_x_position - WorkZone::WIDTH)
				elsif particle_antenna_x_position < 0.0
					particle.data[antenna_number].coordinates.x = particle_antenna_x_position.abs
				end
			end

			particle_antenna_y_position = particle.data[antenna_number].coordinates.y
			if particle_antenna_y_position > WorkZone::HEIGHT or particle_antenna_y_position < 0.0
				speed[antenna_number][:y] *= -1.0
				if particle_antenna_y_position > WorkZone::HEIGHT
					particle.data[antenna_number].coordinates.y = WorkZone::HEIGHT - (particle_antenna_y_position - WorkZone::HEIGHT)
				elsif particle_antenna_y_position < 0.0
					particle.data[antenna_number].coordinates.y = particle_antenna_y_position.abs
				end
			end

			particle.data[antenna_number].rotation = Math::angle_to_zero_pi_range(particle.data[antenna_number].rotation)
		end
	end


	def create_particles_and_their_speeds
		particles = []
		particle_speeds = []
		PARTICLES.times do
			particle = Deployment::AntennaGroup.new(@antenna_manager.create_random_group)
			particle.update_score(@method)
			particles.push(particle)
			particle_speeds.push( create_random_particle_speed )
		end
		[particles, particle_speeds]
	end


	def create_random_particle_speed
		speed = {}
		@antenna_manager.antennae_count.times do |i|
			speed[i] = {
					x: [rand(-25.0..-5.0), rand(5.0..25.0)].sample,
					y: [rand(-25.0..-5.0), rand(5.0..25.0)].sample,
					rotation: rand(0.0..0.2*Math::PI)
			}
		end
		speed
	end
end