class MI::RssCoverage

	def self.generate_coverage
		antennas = []
		(1..16).each do |antenna_number|
			antennas.push(Antenna.new(antenna_number))
		end

		height_number = 0
		reader_power = 30
		step = 5

		rss_map = {}
		(0..500).step(step).each do |x|
			(0..500).step(step).each do |y|
				puts x.to_s
				antennas.each do |antenna|
					rss_map[antenna.number] ||= {max_step: step, data: {}, antenna: antenna}
					rss_map[antenna.number][:data][x] ||= {}
					rss_map[antenna.number][:data][x][y] = MI::Rss.theoretical_rss(antenna, Point.new(x, y), height_number, reader_power)
				end
			end
		end

		rss_map
	end

end