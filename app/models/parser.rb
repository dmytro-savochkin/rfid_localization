class Parser < ActiveRecord::Base

  class << self

    def parse(height = 41, chosen_reader_power = 21, frequency = 'multi', shrinkage = false, all_tags_for_sum = [])
      path = Rails.root.to_s + "/app/raw_input/data/" + height.to_s + '/' + frequency.to_s + '/'

      if all_tags_for_sum.present?
        result = {}

        TagInput.tag_ids.each do |tag_id|
          tags_for_sum = all_tags_for_sum.map{|v| v[tag_id.to_s]}

          tag = TagInput.new(tag_id.to_s, 16)
          tag.fill_average_mi_values(tags_for_sum, {:rss => -70.0, :rr => 0.1})
          result[tag_id] = tag
        end

      else

        result = parse_for_tags(path, chosen_reader_power * 100, shrinkage)

      end

      result
    end








    def parse_for_tags(frequency_dir_path, reader_power, shrinkage)
      tags_data = {}

      (1..16).each do |antenna_number|
        antenna = Antenna.new(antenna_number, Zone::POWERS_TO_SIZES[reader_power/100])
        antenna_code = antenna.file_code
        file_path = frequency_dir_path + antenna_code + "/" + antenna_code + '_' + reader_power.to_s + '.xls'

        sheet = Roo::Excel.new file_path
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
          data[frequency][height][axis] ||= {}
          path = Rails.root.to_s + "/app/raw_input/data/tag_by_lines/" +
              axis_human_name.to_s + '/' + height.to_s + '/' + frequency.to_s + '/'

          data[frequency][height][axis]['sum'] = {}
          data[frequency][height][axis]['product'] = {}
          (20..24).step(1) do |reader_power|
            file_name = height.to_s + '-' + frequency.to_s + '_' + (reader_power*100).to_s + '.xls'
            data[frequency][height][axis][reader_power] = parse_for_tags_in_lines(path, file_name)

            data[frequency][height][axis][reader_power].each do |rr_graph_point|
              distance = rr_graph_point[0]
              rr = rr_graph_point[1]
              data[frequency][height][axis]['sum'][distance] ||= 0.0
              data[frequency][height][axis]['product'][distance] ||= 1.0
              data[frequency][height][axis]['sum'][distance] += rr
              data[frequency][height][axis]['product'][distance] *= rr
            end

          end

          data[frequency][height][axis]['sum'] = normalize data[frequency][height][axis]['sum'].map{|k,v|[k,v]}.sort
          data[frequency][height][axis]['product'] = normalize data[frequency][height][axis]['product'].map{|k,v|[k,v]}.sort
        end
      end

      data
    end



    def normalize(array)
      max_rr = array.map{|e|e.last}.max
      array.map{|e|[e.first, e.last/max_rr]}
    end



    def parse_for_tags_in_lines(path, file_name)
      full_path = path + file_name
      sheet = Roo::Excel.new full_path
      sheet.default_sheet = sheet.sheets.first
      antenna_max_read_count = sheet.column(3).map(&:to_i).max
      tags_count = sheet.last_row - 1

      tags_data = []
      1.upto(tags_count) do |tag_number|
        row = sheet.row tag_number + 1
        tag_id = row[1].to_s
        tag_distance = tag_line_id_to_distance tag_id
        tag_rr = row[2].to_f / antenna_max_read_count

        tags_data.push [tag_distance, tag_rr]
      end

      (-300..300).step(10) do |distance|
        tags_data.push [distance, 0.0] if tags_data[distance].nil?
      end

      tags_data.sort
    end



    def tag_line_id_to_distance(id)
      (id.to_s[-2..-1].to_i - 29) * 10
    end

  end
end