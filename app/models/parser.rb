class Parser < ActiveRecord::Base

  class << self

    def parse(height = 41, chosen_reader_power = 21, frequency = 'multi', shrinkage = false)
      path = Rails.root.to_s + "/app/raw_input/data/" + height.to_s + '/' + frequency.to_s + '/'

      if chosen_reader_power == :sum
        reader_powers = (20..23)
        mi_types = [:rr, :rss, :a]

        result = {}
        counts = {}

        reader_powers.each do |reader_power|
          current_power_tags_data = parse_for_tags(path, reader_power * 100, shrinkage)
          current_power_tags_data.each do |tag_id, current_power_tag_data|

            result[tag_id] ||= TagInput.new(tag_id)
            counts[tag_id] ||= {}

            mi_types.each do |mi_type|
              counts[tag_id][mi_type] ||= {}
              (1..16).each do |antenna_number|
                mi = current_power_tag_data.answers[mi_type][:average][antenna_number]
                if mi.present?
                  result[tag_id].answers_count += 1 if mi_type == :a and mi == 1.0 and reader_power == reader_powers.max
                  result[tag_id].answers[mi_type][:average][antenna_number] ||= 0.0
                  result[tag_id].answers[mi_type][:average][antenna_number] += mi
                  counts[tag_id][mi_type][antenna_number] ||= 0
                  counts[tag_id][mi_type][antenna_number] += 1
                end
              end
            end
          end
        end

        result.each do |tag_id, tag_data|
          mi_types.each do |mi_type|
            (1..16).each do |antenna_number|
              if tag_data.answers[mi_type][:average][antenna_number].present?
                tag_data.answers[mi_type][:average][antenna_number] =
                    tag_data.answers[mi_type][:average][antenna_number].to_f /
                    counts[tag_id][mi_type][antenna_number]
              end
            end
          end
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