class Parser < ActiveRecord::Base

  class << self

    def parse
      data = {}

      heights = [41, 69, 98, 116]
      frequencies = %w(902 915 928 multi)
      reader_powers = (14..30)

      height = 41
      data[height] ||= {}
      frequency = 'multi'
      data[height][frequency] ||= {}
      reader_power = 22

      path = Rails.root.to_s + "/app/raw_input/data/" + height.to_s + '/' + frequency.to_s + '/'
      data[height][frequency][reader_power] = parse_for_tags(path, reader_power * 100)

      data
    end



    def parse_for_tags(frequency_dir_path, reader_power)
      tags_data = {}

      (1..16).each do |antenna_number|
        antenna = Antenna.new antenna_number
        antenna_code = antenna.file_code
        file_path = frequency_dir_path + antenna_code + "/" + antenna_code + '_' + reader_power.to_s + '.xls'

        sheet = Roo::Excel.new file_path
        sheet.default_sheet = sheet.sheets.first
        antenna_max_read_count = sheet.column(3).map(&:to_i).max
        tags_count = sheet.last_row - 1
        1.upto(tags_count) do |tag_number|
          row = sheet.row tag_number + 1
          tag_id = row[1].to_s
          tag_rss = row[5].to_f
          tag_count = row[2].to_i
          tag_rr = tag_count.to_f / antenna_max_read_count

          tags_data[tag_id] ||= Tag.new row[1].to_s



          # generating gaussian distribution of RSS
          #gen = Rubystats::NormalDistribution.new(tag_rss, 5)
          #iterations_to_run = (1..antenna_max_read_count).to_a.sample(tag_count)
          #iterations_to_run.each do |iteration|
          #  data[tag_id][:rss][:detailed][antenna_number] ||= []
          #  data[tag_id][:rss][:detailed][antenna_number][iteration] = gen.rng
          #end


          tags_data[tag_id].answers[:a][:average][antenna_number] = 1
          tags_data[tag_id].answers[:rss][:average][antenna_number] = tag_rss
          tags_data[tag_id].answers[:rr][:average][antenna_number] = tag_rr
        end

      end

      tags_data
    end



  end
end