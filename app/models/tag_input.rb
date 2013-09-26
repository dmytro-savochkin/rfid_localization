class TagInput
  START = 30
  STEP = 40

  attr_accessor :answers, :position, :id, :answers_count

  def initialize(id, antennae_count = 16)
    @id = id.to_s
    @position = Point.new(*id_to_position)
    @answers = {
        :a => {:average => {}, :adaptive => {}},
        :rss => {:average => {}, :adaptive => {}},
        :rr => {:average => {}}
    }
    @answers_count = 0

    1.upto(antennae_count) do |antenna|
      @answers[:a][:average][antenna] = 0
      @answers[:a][:adaptive][antenna] = 0
    end
  end



  def clean_from_antenna(antenna_number)
    @answers[:a][:average][antenna_number] = 0
    @answers[:a][:adaptive][antenna_number] = 0
    @answers[:rss][:average].delete antenna_number
    @answers[:rss][:adaptive].delete antenna_number
    @answers[:rr][:average].delete antenna_number
    self
  end



  def nearest_antenna
    x_code = @id[-4..-3]
    y_code = @id[-2..-1]

    tags_in_zone_row = 3

    x_antenna_number = ((tag_x_code_to_number(x_code) + 1).to_f / tags_in_zone_row).ceil
    y_antenna_number = (y_code.to_f / tags_in_zone_row).ceil

    antenna_number = y_antenna_number + (x_antenna_number - 1) * 4
    Antenna.new antenna_number
  end


  def zone
    nearest_antenna.number
  end




  class << self
    def tag_ids
      tags_ids = []

      letters = ('A'..'F')
      numbers = (1..12)

      letters.each do |letter|
        2.times do |time|
          numbers.each do |number|
            number = "%02d" % number
            if time == 0
              letter_combination = "0" + letter.to_s
            else
              letter_combination = letter.to_s * 2
            end
            tags_ids.push(letter_combination.to_s + number.to_s)
          end
        end
      end
      tags_ids
    end

    def clone(tag)
      cloned_tag = TagInput.new tag.id
      tag.answers.each do |answer_type, answer_hash|
        answer_hash.each do |answer_subtype, data|
          cloned_tag.answers[answer_type][answer_subtype] = data.dup
        end
      end
      cloned_tag
    end


    def from_point(point)
      return false unless point.kind_of? Point
      x = point.x
      y = point.y

      letter_array = ('A'..'F').to_a

      first_letter_code = ((x - (6*STEP + START)) / STEP)
      second_letter_code = ((x - START) / STEP)
      second_letter_code -= 6 if second_letter_code >= 6
      if first_letter_code < 0
        first_letter = '0'
      else
        first_letter = letter_array[first_letter_code.round].to_s
      end
      second_letter = letter_array[second_letter_code.round].to_s

      number = ((y - START) / STEP + 1).to_i
      digits = number.to_s
      digits = '0' + digits if number < 10
      id = first_letter + second_letter + digits

      TagInput.new(id)
    end
  end



  private


  # 0F02 => [270, 110]
  def id_to_position

    x_code = @id[-4..-3]
    y_code = @id[-2..-1]

    x_code_number = tag_x_code_to_number(x_code)
    y_code_number = y_code.to_i - 1

    number_to_centimeters = lambda {|number| START + (number) * STEP}
    x = number_to_centimeters.call x_code_number
    y = number_to_centimeters.call y_code_number

    [x, y]
  end
  def tag_x_code_to_number(x_code)
    number = letter_to_number x_code[1]
    number += 6 if x_code[0] != '0'
    number
  end
  def letter_to_number(letter)
    letter.downcase.ord - 'a'.ord
  end
end
