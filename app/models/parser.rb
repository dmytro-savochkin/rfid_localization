class Parser < ActiveRecord::Base

  class << self

    def parse(height = 41, chosen_reader_power = 21, frequency = 'multi')
      path = Rails.root.to_s + "/app/raw_input/data/" + height.to_s + '/' + frequency.to_s + '/'

      if chosen_reader_power == 'sum' or chosen_reader_power == 'prod'
        reader_powers = (20..25)

        data = {}
        reader_powers.each do |reader_power|
          tags_data = parse_for_tags(path, reader_power * 100)
          tags_data.each do |tag_id, tag_data|

            if data[tag_id].nil?
              data[tag_id] = tag_data
            else
              integral_rr_hash = data[tag_id].answers[:rr][:average]
              (1..16).each do |antenna_number|
                rr = tags_data[tag_id].answers[:rr][:average][antenna_number]
                integral_rr_hash[antenna_number] ||= 0.0
                integral_rr_hash[antenna_number] ||= 1.0
                unless rr.nil?
                  integral_rr_hash[antenna_number] += rr if chosen_reader_power == 'sum'
                  if chosen_reader_power == 'prod'
                    if integral_rr_hash[antenna_number] == 0.0
                      integral_rr_hash[antenna_number] = rr
                    else
                      integral_rr_hash[antenna_number] *= rr if rr > 0.0
                    end
                  end
                end
              end
            end

          end
        end
      else
        data = parse_for_tags(path, chosen_reader_power * 100)
      end

      data
    end



    def parse_for_tags(frequency_dir_path, reader_power)
      tags_data = {}

      (1..16).each do |antenna_number|
        antenna = Antenna.new(antenna_number, Zone::POWERS_TO_SIZES[reader_power/100])
        antenna_code = antenna.file_code
        file_path = frequency_dir_path + antenna_code + "/" + antenna_code + '_' + reader_power.to_s + '.xls'

        sheet = Roo::Excel.new file_path
        sheet.default_sheet = sheet.sheets.first
        antenna_max_read_count = sheet.column(3).map(&:to_i).max
        tags_count = sheet.last_row - 1
        1.upto(tags_count) do |tag_number|
          row = sheet.row tag_number + 1
          tag_id = row[1][-4..-1].to_s
          tag_rss = row[6].to_f
          tag_count = row[2].to_i
          tag_rr = tag_count.to_f / antenna_max_read_count

          tags_data[tag_id] ||= TagInput.new(row[1].to_s)

          tags_data[tag_id].answers_count += 1
          tags_data[tag_id].answers[:a][:average][antenna_number] = 1
          tags_data[tag_id].answers[:a][:adaptive][antenna_number] = 1 if tag_rss > -70.0
          tags_data[tag_id].answers[:rss][:average][antenna_number] = tag_rss
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