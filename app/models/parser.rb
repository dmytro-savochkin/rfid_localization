class Parser < ActiveRecord::Base

  class << self

    def parse(height = 41, chosen_reader_power = 21, frequency = 'multi', shrinkage = false, tags_for_sum = [])
      prefix = Rails.root.to_s + "/app/raw_input/data/" + height.to_s + '/'
      path = prefix + frequency.to_s + '/'
      reserve_path = prefix + MI::Base::DEFAULT_FREQUENCY.to_s + '/'

      if tags_for_sum.present?
        result = {}

        TagInput.tag_ids.each do |tag_id|
          tag_data_for_sum = tags_for_sum.map{|v| v[tag_id.to_s]}

          tag = TagInput.new(tag_id.to_s, 16)
          tag.fill_average_mi_values(tag_data_for_sum, {:rss => -70.0, :rr => 0.1})
          result[tag_id] = tag
        end

      else

        result = parse_for_tags(path, reserve_path, chosen_reader_power * 100, shrinkage)

      end

      result
    end








    def parse_for_tags(path, reserve_path, reader_power, shrinkage)
      tags_data = {}

      (1..16).each do |antenna_number|
        antenna = Antenna.new(antenna_number, Zone::POWERS_TO_SIZES[reader_power/100])
        antenna_code = antenna.file_code

        file_postfix = antenna_code + "/" + antenna_code + '_' + reader_power.to_s + '.xls'
        file_path = path + file_postfix
        reserve_file_path = reserve_path + file_postfix

        begin
          sheet = Roo::Excel.new(file_path)
        rescue IOError
          sheet = Roo::Excel.new(reserve_file_path)
        end

        sheet.default_sheet = sheet.sheets.first
        antenna_max_read_count = sheet.column(3).map(&:to_i).max
        tags_count = sheet.last_row - 1

        rss_column_number = 7

        rsses = sheet.column(rss_column_number)[1..-1].map(&:to_f)
        rres = sheet.column(3)[1..-1].map{|reads| reads.to_f / antenna_max_read_count}

        if shrinkage
          rsses = Optimization::JamesStein.new.optimize_data( rsses )
          rres = Optimization::JamesStein.new.optimize_data( rres )
        end

        (1..tags_count).each_with_index do |tag_number, index|
          row = sheet.row tag_number + 1
          tag_id = row[1][-4..-1].to_s
          tag_rss = rsses[index]
          tag_rr = rres[index]

          tags_data[tag_id] ||= TagInput.new(row[1].to_s[-4..-1])

          tags_data[tag_id].answers_count += 1
          tags_data[tag_id].answers[:a][:average][antenna_number] = 1
          tags_data[tag_id].answers[:a][:adaptive][antenna_number] = 1 if tag_rss > -70.0
          tags_data[tag_id].answers[:rss][:average][antenna_number] = tag_rss
          tags_data[tag_id].answers[:rss][:adaptive][antenna_number] = tag_rss if tag_rr > 0.1
          tags_data[tag_id].answers[:rr][:average][antenna_number] = tag_rr
        end
      end

      tags_data
    end




















    def parse_tag_lines_data(frequency = 'multi')
      data = {}
      data[frequency] ||= {}

      heights = [28, 56, 57, 73, 74, 101]

      axes_data = {
          :near_the_door => 'x',
          :far_from_the_door => 'y'
      }

      heights.each do |height|
        data[frequency][height] ||= {}
        axes_data.each do |axis_human_name, axis|
          data[frequency][height][axis] ||= {rss: {sum: {}, product: {}}, rr: {sum: {}, product: {}}}
          path = Rails.root.to_s + "/app/raw_input/data/tag_by_lines/" +
              axis_human_name.to_s + '/' + height.to_s + '/' + frequency.to_s + '/'

					[:rss, :rr].each do |mi_type|
					#[:rss].each do |mi_type|
						(20..30).step(1) do |reader_power|
							file_name = height.to_s + '-' + frequency.to_s + '_' + (reader_power*100).to_s + '.xls'
							data[frequency][height][axis][mi_type][reader_power] = parse_for_tags_in_lines(path, file_name, mi_type)

							data[frequency][height][axis][mi_type][reader_power].each do |rr_graph_point|
								distance = rr_graph_point[0]
								mi = rr_graph_point[1]
								data[frequency][height][axis][mi_type][:sum][distance] ||= []
								data[frequency][height][axis][mi_type][:product][distance] ||= []
								data[frequency][height][axis][mi_type][:sum][distance] << mi
								data[frequency][height][axis][mi_type][:product][distance] << mi
							end
						end
						#if mi_type == :rr
						data[frequency][height][axis][mi_type][:sum].each do |distance, mi_values|
							mean = mi_values.mean
							data[frequency][height][axis][mi_type][:sum][distance] = mean
						end
						if mi_type == :rr
							max = data[frequency][height][axis][mi_type][:sum].values.max
							data[frequency][height][axis][mi_type][:sum].each do |distance, mi|
								data[frequency][height][axis][mi_type][:sum][distance] = mi / max
							end
						end
						data[frequency][height][axis][mi_type][:sum] = data[frequency][height][axis][mi_type][:sum].to_a
						#data[frequency][height][axis][mi_type][:product] = normalize data[frequency][height][axis][mi_type][:product].map{|k,v|[k,v]}.sort
						#else
						#	data[frequency][height][axis][mi_type][:sum] =
						#			data[frequency][height][axis][mi_type][:sum].mean
						#end
					end
        end
      end

      data
    end



    def normalize(array)
      max_rr = array.map{|e|e.last}.max
      array.map{|e|[e.first, e.last/max_rr]}
    end



    def parse_for_tags_in_lines(path, file_name, mi_type)
      full_path = path + file_name
      sheet = Roo::Excel.new full_path
      sheet.default_sheet = sheet.sheets.first
      antenna_max_read_count = sheet.column(3).map(&:to_i).max
      tags_count = sheet.last_row - 1

      tags_data = {}
      1.upto(tags_count) do |tag_number|
        row = sheet.row tag_number + 1
        tag_id = row[1].to_s
        tag_distance = tag_line_id_to_distance tag_id

				if mi_type == :rr
					tag_mi = row[2].to_f / antenna_max_read_count
				else
					tag_mi = row[6].to_f
				end

        tags_data[tag_distance] = tag_mi
      end

			if mi_type == :rr
				default_mi = 0.0
			else
				default_mi = -90.0
			end

      (-300..300).step(10) do |distance|
        tags_data[distance] = default_mi if tags_data[distance].nil?
      end

      tags_data.to_a.sort
		end


		def parse_time_tag_responses
			path = Rails.root.to_s + "/app/raw_input/rss_time.xlsx"
			book = Roo::Excelx.new(path)
			tags = {:by_distance => {}, :by_tag => {}}
			book.sheets.each do |sheet_name|
				sheet = sheet_name.to_i
				book.default_sheet = sheet_name
				tags[:by_distance][sheet] = {}
				tags[:by_tag][sheet] = {}
				column = 0
				while column <= book.last_column
					time = column / 2
					(2..19).each do |row_number|
						row = book.row row_number
						tag_id = row[column + 1].to_s
						unless tag_id.empty?
							tag_distance = tag_time_id_to_distance(tag_id)
							tag_rss = row[column]
							tags[:by_distance][sheet][time] ||= {}
							tags[:by_distance][sheet][time][tag_distance] = tag_rss
							tags[:by_tag][sheet][tag_id[-4..-1]] ||= Array.new(book.last_column/2)
							tags[:by_tag][sheet][tag_id[-4..-1]][time] = tag_rss
						end
					end
					column += 2
				end
			end
			tags
		end


		def tag_time_id_to_distance(id)
			(id.to_s[-2..-1].to_i - 21).abs * 10
		end
    def tag_line_id_to_distance(id)
      (id.to_s[-2..-1].to_i - 29) * 10
    end

  end
end