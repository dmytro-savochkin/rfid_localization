class TagSetsManager

  attr_reader :tags_input

  def initialize(heights, type, save = false, length = nil)
    @type = type
    @heights_combinations = heights
    @save_and_use_last_data = save
    @length = length

    if @type == :virtual
      @generator = MiGenerator.new
      @virtual_tags_positions = {
          :train => @generator.create_grid_positions(length[:train], 40),
          :setup => @generator.create_grid_positions(length[:setup], 20),
          :test => @generator.create_random_positions(length[:test])
      }
    end

    max_reader_power = 30

    if @save_and_use_last_data and @type == :virtual
      if File.exists?(tags_data_file_path)
        @tags_input = read_tags_input_from_file
      else
        @tags_input = get_tags_input(max_reader_power)
        save_tags_input_in_file
      end
    else
      @tags_input = get_tags_input(max_reader_power)
    end

  end







  private


  def tags_data_file_path
    save_dir = Rails.root.to_s + "/app/raw_output/tags_data/"
    file_name = @heights_combinations.to_s + '_' + @type.to_s
    file_name += '_' + @length.to_s if @length.present?
    save_dir + file_name
  end

  def read_tags_input_from_file
    Marshal.load( File.read(tags_data_file_path) )
  end

  def save_tags_input_in_file
    path_to_file = tags_data_file_path
    if File.exists?(path_to_file)
      nil
    else
      File.open(path_to_file, 'wb') { |f| f.write( Marshal.dump(@tags_input) ) }
    end
  end







  def get_train_and_test_heights
    if @heights_combinations == :all
      train_heights = [[3],[2],[0],[2],[3],[0],[2],[0]]
      setup_heights = [2,   3,  2,  0,  0,  3,  0,  2]
      test_heights =  [0,   0,  1,  1,  2,  2,  3,  3]
    elsif @heights_combinations == :basic
      train_heights = [[3], [3], [0], [0]]
      setup_heights = [ 2,   0,   2,   3 ]
      test_heights =  [ 0,   2,   3,   1 ]
    elsif @heights_combinations == :double_train
      train_heights = [[3,2], [3,0], [0,2], [0,3]]
      #train_heights = [[3,2], [3,0], [0,3], [0,2]]
      setup_heights = [2,0,2,3]
      test_heights =  [0,2,3,1]
    else
      train_heights = [[3]]
      setup_heights = [2]
      test_heights =  [0]
    end
    [train_heights, setup_heights, test_heights]
  end


  #
  #def generate_tags_input(tags_count, max_reader_power = 30)
  #  tags_input = {}
  #
  #  generator = MiGenerator.new
  #  tags_positions = generator.create_positions(tags_count.values.max)
  #
  #  all_train_heights, all_setup_heights, all_test_heights = get_train_and_test_heights
  #
  #  (20..max_reader_power).each do |reader_power|
  #    tags = []
  #
  #    heights_combinations = all_train_heights.length
  #    heights_combinations.times do |index|
  #      train_heights = all_train_heights[index]
  #      setup_height = all_setup_heights[index]
  #      test_height = all_test_heights[index]
  #
  #      tags.push({
  #        :train => generator.create_group(tags_count[:train], tags_positions, reader_power, train_height),
  #        :setup => generator.create_group(tags_count[:setup], tags_positions, reader_power, setup_height),
  #        :test => generator.create_group(tags_count[:test], tags_positions, reader_power, test_height),
  #        :heights => {:train => train_height, :setup => setup_height, :test => test_height}
  #      })
  #    end
  #
  #    tags_input[reader_power] = tags
  #  end
  #  tags_input
  #end
  #
  #
  #def get_tags_input(max_reader_power = 24)
  #  tags_input = {}
  #  all_train_heights, all_setup_heights, all_test_heights = get_train_and_test_heights
  #  (20..max_reader_power).each do |reader_power|
  #    tags = []
  #
  #    heights_combinations = all_train_heights.length
  #    heights_combinations.times do |index|
  #      train_heights = all_train_heights[index]
  #      setup_height = all_setup_heights[index]
  #      test_height = all_test_heights[index]
  #
  #      cache_name = 'parser_real_data_' + reader_power.to_s + '_' + @heights_combinations.to_s + '_' + index.to_s
  #      parser_data = Rails.cache.fetch(cache_name, :expires_in => 5.days) do
  #        {
  #            :train => gather_train_data(train_heights, reader_power),
  #            :setup => Parser.parse(MI::Base::HEIGHTS[setup_height], reader_power, frequency),
  #            :test => Parser.parse(MI::Base::HEIGHTS[test_height], reader_power, frequency),
  #            :heights => {:train => train_heights, :setup => setup_height, :test => test_height}
  #        }
  #      end
  #
  #      tags.push(parser_data)
  #    end
  #
  #    tags_input[reader_power] = tags
  #  end
  #  tags_input
  #end







  def get_tags_input(max_reader_power)
    tags_input = {}
    all_train_heights, all_setup_heights, all_test_heights = get_train_and_test_heights
    (20..max_reader_power).each do |reader_power|
      tags = []

      heights_combinations = all_train_heights.length
      heights_combinations.times do |index|
        train_heights = all_train_heights[index]
        setup_height = all_setup_heights[index]
        test_height = all_test_heights[index]

        if @type == :virtual
          tags.push({
              :train => gather_train_data(train_heights, reader_power),
              :setup => @generator.create_group(@virtual_tags_positions[:setup], reader_power, setup_height),
              :test => @generator.create_group(@virtual_tags_positions[:test], reader_power, test_height),
              :heights => {:train => train_heights, :setup => setup_height, :test => test_height}
          })
        else
          cache_name = 'parser_real_data_' + reader_power.to_s + '_' + @heights_combinations.to_s + '_' + index.to_s
          parser_data = Rails.cache.fetch(cache_name, :expires_in => 5.days) do
            {
                :train => gather_train_data(train_heights, reader_power),
                :setup => Parser.parse(MI::Base::HEIGHTS[setup_height], reader_power, MI::Base::FREQUENCY),
                :test => Parser.parse(MI::Base::HEIGHTS[test_height], reader_power, MI::Base::FREQUENCY),
                :heights => {:train => train_heights, :setup => setup_height, :test => test_height}
            }
          end
          tags.push(parser_data)
        end

      end
      tags_input[reader_power] = tags
    end
    tags_input
  end





  def gather_train_data(train_heights, reader_power)
    full_train_data = {}
    train_heights.each do |train_height|

      if @type == :virtual
        train_data = @generator.create_group(@virtual_tags_positions[:train], reader_power, train_height)
      else
        train_data = Parser.parse(MI::Base::HEIGHTS[train_height], reader_power, MI::Base::FREQUENCY)
      end

      train_data.each do |tag_id, tag_data|
        additional_index = ''
        while full_train_data[tag_id + additional_index.to_s] != nil do
          additional_index = 1 if additional_index == ''
          additional_index += 1
        end
        full_train_data[tag_id.to_s + additional_index.to_s] = tag_data
      end
    end
    full_train_data
  end



end