class TagSetsManager

  attr_reader :tags_input

  def initialize(heights, type, length = nil)
    @type = type
    @heights_combinations = heights

    if @type == :virtual
      @tags_input = generate_tags_input(length)
    else
      @tags_input = get_tags_input
    end
  end







  private

  def get_train_and_test_heights
    if @heights_combinations == :all
      train_heights = [3,2,0,2,3,0,2,0]
      setup_heights = [2,3,2,0,0,3,0,2]
      test_heights =  [0,0,1,1,2,2,3,3]
    elsif @heights_combinations == :basic
      train_heights = [3,3,0]
      setup_heights = [2,0,2]
      test_heights =  [0,2,3]
    else
      train_heights = [3]
      setup_heights = [2]
      test_heights =  [0]
    end
    [train_heights, setup_heights, test_heights]
  end



  def generate_tags_input(tags_count, max_reader_power = 24)
    generator = MiGenerator.new
    tags_input = {}
    tags_positions = generator.create_positions(tags_count.values.max)

    train_heights, setup_heights, test_heights = get_train_and_test_heights

    (20..max_reader_power).each do |reader_power|
      tags = []
      train_heights.each_with_index do |train_height, index|
        setup_height = setup_heights[index]
        test_height = test_heights[index]
        tags.push({
          :train => generator.create_group(tags_count[:train], tags_positions, reader_power, train_height),
          :setup => generator.create_group(tags_count[:setup], tags_positions, reader_power, setup_height),
          :test => generator.create_group(tags_count[:test], tags_positions, reader_power, test_height),
          :heights => {:train => train_height, :setup => setup_height, :test => test_height}
        })
      end

      tags_input[reader_power] = tags
    end
    tags_input
  end


  def get_tags_input(max_reader_power = 24)
    frequency = MI::Base::FREQUENCY

    tags_input = {}
    train_heights, setup_heights, test_heights = get_train_and_test_heights
    (20..max_reader_power).each do |reader_power|
      tags = []

      train_heights.each_with_index do |train_height, index|
        setup_height = setup_heights[index]
        test_height = test_heights[index]
        tags.push({
            :train => Parser.parse(MI::Base::HEIGHTS[train_height], reader_power, frequency),
            :setup => Parser.parse(MI::Base::HEIGHTS[setup_height], reader_power, frequency),
            :test => Parser.parse(MI::Base::HEIGHTS[test_height], reader_power, frequency),
            :heights => {:train => train_height, :setup => setup_height, :test => test_height}
        })
      end

      tags_input[reader_power] = tags
    end
    tags_input
  end
end