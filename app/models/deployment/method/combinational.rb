class Deployment::Method::Combinational < Deployment::Method::Base
	METHODS = {
			trilateration: 1.0 / 3,
			intersectional: 1.0 / 3,
			fingerprinting: 1.0 / 3
	}

	def initialize
		@mi_a_c_code = MI::A::CCode.new
	end

	def calculate_score(antennae, log = true)
		work_zone = WorkZone.new(antennae)
		coverage, coverage_in_center = calculate_coverage(work_zone)
		buffer = []

		results = {}
		weights = {}
		score = 0.0
		max_step = 0
		score_map = {data: {}}
		METHODS.keys.each do |method|
			buffer << 'starting ' + method.to_s + ' at ' + Time.now.strftime('%H:%M:%S.%L') if log
			results[method] = {}
			solver_class = ('Deployment::Method::Single::' + method.to_s.capitalize).split('::').inject(Object) do |o,c|
				o.const_get c
			end
			max_step = solver_class.const_get(:STEP) if solver_class.const_get(:STEP) > max_step
			solver_object = solver_class.new(work_zone, coverage, coverage_in_center)
			solver_object.make_preparation
			result = solver_object.calculate_result
			results[method][:step] = solver_class.const_get(:STEP)
			results[method][:antennae] = work_zone.antennae
			results[method][:result] = result
			buffer << 'ending ' + method.to_s + ' at ' + Time.now.strftime('%H:%M:%S.%L') if log
		end


		rates = {}
		total_work_zone_area = ((work_zone.width.to_f / results[:fingerprinting][:step]) + 1) ** 2
		center_work_zone_area = (((work_zone.width.to_f - 2*Deployment::Method::Base::CENTER_SHIFT) / Deployment::Method::Base::MINIMAL_STEP) + 1) ** 2
		rates[:covering_by_three] = results[:fingerprinting][:result][:three_antennae_covering_area] /
				total_work_zone_area
		rates[:covering_by_one] = results[:fingerprinting][:result][:one_antenna_covering_area] /
				total_work_zone_area
		rates[:covering_by_one_in_center] = coverage_in_center.values.to_a.map{|e| e.values}.flatten.select{|c| c >= 1}.length.to_f /
				center_work_zone_area
		rates[:covering_by_one_big] = results[:fingerprinting][:result][:one_antenna_big_covering_area] /
				total_work_zone_area


		weights[:trilateration] = rates[:covering_by_three]
		weights[:fingerprinting] = 1.0 + ((1.0 - rates[:covering_by_three]) / 2)
		weights[:intersectional] = 1.0 + ((1.0 - rates[:covering_by_three]) / 2)

		score_map[:max_step] = max_step
		score_map[:antennae] = antennae
		(0..WorkZone::WIDTH).step(max_step).each do |x|
			score_map[:data][x] ||= {}
			(0..WorkZone::HEIGHT).step(max_step).each do |y|
				score_map[:data][x][y] ||= 0.0
				weight = 1.0 / METHODS.keys.select{|m| results[m][:result][:normalized_data][x] and results[m][:result][:normalized_data][x][y] }.length
				METHODS.keys.each do |method|
					method_normalized_data = results[method][:result][:normalized_data]
					if method_normalized_data[x] and method_normalized_data[x][y]
						score_map[:data][x][y] += weight * method_normalized_data[x][y]
					end
				end
			end
		end


		METHODS.keys.each do |method|
			weight = weights[method]
			score += results[method][:result][:normalized_average_data] * weight * METHODS[method]
		end
		score *= rates[:covering_by_one] ** 3
		score *= rates[:covering_by_one_in_center] ** 2

		if log
			buffer << 'SCORE IS ' + score.to_s
			buffer << ''
		end

		[results, score, rates, score_map, buffer]
	end
end