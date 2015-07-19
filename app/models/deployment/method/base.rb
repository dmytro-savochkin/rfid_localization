class Deployment::Method::Base
	class WrongStepValue < StandardError
	end

	attr_reader :work_zone

	MINIMAL_STEP = 2
	CENTER_SHIFT = 50.0

	def initialize(work_zone, coverage = nil, coverage_in_center = nil)
		@mi_a_c_code = MI::A::CCode.new
		@work_zone = work_zone
		@coverage, @coverage_in_center = [coverage, coverage_in_center] || calculate_coverage()
		if self.class.ancestors.include? Deployment::Method::Single::Base
			if self.class.const_get(:STEP) < Deployment::Method::Base::MINIMAL_STEP
				raise WrongStepValue.new(self.class.const_get(:STEP))
			end
		end
	end

	def calculate_coverage(work_zone = @work_zone)
		coverage = {}
		coverage_in_center = {}
		(0..work_zone.width.to_i).step(MINIMAL_STEP) do |x|
			coverage[x] ||= {}
			(0..work_zone.height.to_i).step(MINIMAL_STEP) do |y|
				coverage[x][y] = 0
				point = Point.new(x, y)
				next if work_zone.inside_obstructions?(point) or work_zone.inside_passages?(point)
				work_zone.antennae.values.each do |antenna|
					inside_ellipse = MI::A.point_in_ellipse?(point, antenna, [antenna.coverage_zone_width, antenna.coverage_zone_height], @mi_a_c_code)
					if inside_ellipse
						blocked = work_zone.points_blocked_by_obstructions?(point, antenna.coordinates)
						unless blocked
							coverage[x][y] += 1
							if point.inside_rectangle(Point.new(CENTER_SHIFT, CENTER_SHIFT), work_zone.width - 2*CENTER_SHIFT, work_zone.width - 2*CENTER_SHIFT)
								coverage_in_center[x] ||= {}
								coverage_in_center[x][y] ||= 0
								coverage_in_center[x][y] += 1
							end
						end
					end
				end
			end
		end
		[coverage, coverage_in_center]
	end

	def make_preparation
	end




	private

	def point_covered_by_at_least_one_antenna?(antennae, point, type = :min)
		antennae.each do |antenna|
			if type == :max
				sizes = [antenna.big_coverage_zone_width, antenna.big_coverage_zone_height]
			else
				sizes = [antenna.coverage_zone_width, antenna.coverage_zone_height]
			end
			if MI::A.point_in_ellipse?(point, antenna, sizes, @mi_a_c_code)
				return true
			end
		end
		false
	end

	def calculate_average(data)
		data.values.to_a.map{|e| e.values}.flatten.mean
	end


end