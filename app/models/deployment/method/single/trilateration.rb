class Deployment::Method::Single::Trilateration < Deployment::Method::Single::Base
	STEP = 2

	def initialize(work_zone, coverage = nil, coverage_in_center = nil)
		super
		#@point_c_code = Point::CCode.new
		@point_c_code = nil
		@c_code = CCode.new
	end

	class CCode
		inline do |builder|
			# http://en.wikipedia.org/wiki/Dilution_of_precision_(GPS)#Computation_of_DOP_Values
			builder.c "
			  VALUE calculate_hdop(VALUE antenna_matrix, double x, double y) {
					int antenna_matrix_len = RARRAY_LEN(antenna_matrix);
					VALUE *antenna_matrix_row = RARRAY_PTR(antenna_matrix_len);

			    double h[3][2];
			    double h_transposed[2][3];
			    double h_transposed_and_h_product[2][2];
			    //double h_transposed_and_w_product[2][3];
			    double q[2][2];
			    double w[3][3];
					int i,j,k;
					double det;
					double result;



			    double c_matrix[3][3];
					VALUE *matrix_row = RARRAY_PTR(antenna_matrix);
			    for (i = 0; i < 3; i++) {
						VALUE *matrix_col = RARRAY_PTR(matrix_row[i]);
						for (j = 0; j < 3; j++) {
							c_matrix[i][j] = NUM2DBL(matrix_col[j]);
							//if(i != j){w[i][j] = 0.0;}
							//else {w[i][j] = 1.0/pow(1.0,2);}
						}
					}


			    for(i = 0; i < 3; i++) {
						if(c_matrix[i][2] == 0.0){
							h[i][0] = 1.0;
							h[i][1] = 1.0;
						}
						else {
							h[i][0] = (c_matrix[i][0] - x) / c_matrix[i][2];
							h[i][1] = (c_matrix[i][1] - y) / c_matrix[i][2];
						}
					}

					for(i = 0; i <= 1; i++) {
						for(j = 0; j <= 2; j++) {
							h_transposed[i][j] = h[j][i];
						}
					}

					/*
					//2x3 x 3x3 = 2x3
					for(i = 0; i <= 1; i++) {
						for(j = 0; j <= 2; j++) {
							h_transposed_and_w_product[i][j] = 0.0;
							for(k = 0; k <= 2; k++) {
								h_transposed_and_w_product[i][j] += h_transposed[i][k] * w[k][j];
							}
						}
					}
					*/

					//2x3 x 3x2 = 2x2
					for(i = 0; i <= 1; i++) {
						for(j = 0; j <= 1; j++) {
							h_transposed_and_h_product[i][j] = 0.0;
							for(k = 0; k <= 2; k++) {
								//h_transposed_and_h_product[i][j] += h_transposed_and_w_product[i][k] * h[k][j];
								h_transposed_and_h_product[i][j] += h_transposed[i][k] * h[k][j];
							}
						}
					}

			    det = h_transposed_and_h_product[0][0] * h_transposed_and_h_product[1][1] - h_transposed_and_h_product[0][1] * h_transposed_and_h_product[1][0];
					result = sqrt(h_transposed_and_h_product[1][1] / det + h_transposed_and_h_product[0][0] / det);

					return rb_float_new(result);
				}
			"
		end
	end



	def calculate_result
		hdop = {}
		normalized_hdop = {}

		(0..@work_zone.width).step(STEP) do |x|
			hdop[x] ||= {}
			normalized_hdop[x] ||= {}
			(0..@work_zone.height).step(STEP) do |y|
				point = Point.new(x, y)

				if @coverage[x][y] >= 3
					distances = {}
					sorted_antennas = @work_zone.antennae.values.sort_by do |antenna|
						distances[antenna.number] = Point.distance(antenna.coordinates, point, @point_c_code)
					end

					next unless point_covered_by_at_least_one_antenna?(sorted_antennas, point)

					#h_matrix = Matrix.build(3, 2) {|row, col| nil }
					##h_matrix = Matrix.build(3, 3) {|row, col| nil }
					##w_matrix = Matrix.build(3, 3) {|row, col| 0.0 }
					##(0..2).each{|i| w_matrix[i, i] = 1.0}
					#sorted_antennas[0..2].each_with_index do |antenna, i|
					#	distance = distances[antenna.number]
					#	h_matrix[i, 0] = (antenna.coordinates.x - point.x) / distance
					#	h_matrix[i, 1] = (antenna.coordinates.y - point.y) / distance
					#	#h_matrix[i, 2] = -1.0
					#end
					#h_matrix = h_matrix.map{|e| if e.nan? then 1.0 else e end}
					##q_matrix = (h_matrix.transpose * w_matrix * h_matrix).inverse
					##gdop[x][y] = Math.sqrt(q_matrix[0,0] + q_matrix[1,1])
					##puts gdop[x][y].to_s
					#q_matrix = (h_matrix.transpose * h_matrix).inverse


					#puts point.to_s
					#puts sorted_antennas[0..2].map{|a| a.coordinates}.to_s
					#puts h_matrix.to_s
					#puts '-'
					#puts q_matrix.to_s
					#puts (q_matrix[0,0] + q_matrix[1,1]).to_s
					#puts ''
					#gdop[x][y] = Math.sqrt(q_matrix[0,0] + q_matrix[1,1])
					hdop[x][y] = @c_code.calculate_hdop(
							sorted_antennas[0..2].map{|a| [a.coordinates.x, a.coordinates.y, distances[a.number]]},
							point.x,
							point.y
					)
					normalized_hdop[x][y] = calculate_normalized_value(hdop[x][y])

					#puts gdop[x][y].to_s
					#puts ''
				end
			end
		end

		average_hdop = calculate_average(hdop)

		{
				data: hdop,
				normalized_data: normalized_hdop,
				average_data: average_hdop,
				normalized_average_data: calculate_normalized_value(average_hdop)
		}
	end




	#def calculate_result_3d
	#	gdop = {}
	#
	#	(0.0..@work_zone.width.to_f).step(STEP) do |x|
	#		gdop[x] ||= {}
	#		(0.0..@work_zone.height.to_f).step(STEP) do |y|
	#			point = Point.new(x, y)
	#
	#
	#			distances = {}
	#			distances_3d = {}
	#			sorted_antennas = @work_zone.antennae.values.sort_by do |antenna|
	#				distances[antenna.number] = antenna.coordinates.distance_to_point(point)
	#				distances_3d[antenna.number] = Math.sqrt(distances[antenna.number]**2 + WorkZone::ROOM_HEIGHT.to_f**2)
	#			end
	#			#sorted_antennas[0..2].each do |antenna|
	#
	#			#h_matrix = Matrix.build(@work_zone.antennae.length, 2) {|row, col| nil }
	#			h_matrix = Matrix.build(4, 3) {|row, col| nil }
	#			sorted_antennas[0..3].each_with_index do |antenna, i|
	#				distance = distances_3d[antenna.number]
	#				h_matrix[i, 0] = (antenna.coordinates.x - point.x) / distance
	#				h_matrix[i, 1] = (antenna.coordinates.y - point.y) / distance
	#				h_matrix[i, 2] = WorkZone::ROOM_HEIGHT.to_f / distance
	#			end
	#			h_matrix = h_matrix.map{|e| if e.nan? then 1.0 else e end}
	#			q_matrix = (h_matrix.transpose * h_matrix).inverse
	#			#puts point.to_s
	#			#puts sorted_antennas[0..2].map{|a|a.number}.to_s
	#			#puts h_matrix.to_s + h_matrix.transpose.to_s
	#			#puts "+" + (h_matrix.transpose * h_matrix).to_s
	#			#puts distances_3d.to_s
	#			#puts '! ' + q_matrix.to_s + ' !'
	#			#puts '========'
	#			#puts ''
	#			gdop[x][y] = Math.sqrt(q_matrix[0,0] + q_matrix[1,1] + q_matrix[2,2])
	#		end
	#	end
	#
	#	average_gdop = calculate_average(gdop)
	#	{
	#			data: gdop,
	#			average_data: average_gdop,
	#			normalized_average_data: calculate_normalized_average(average_gdop)
	#	}
	#end



	private

	def calculate_normalized_value(hdop)
		return 0.0 if hdop.nan?
		max_gdop = 2.5 # excellent/good gdop value according to some sources
		1.0 - ([hdop, max_gdop].min - 1) / (max_gdop - 1) # minus 1 because gdop cannot be less than 1
	end
end