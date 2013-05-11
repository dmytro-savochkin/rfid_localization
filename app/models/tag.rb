class Tag
  attr_accessor :answers, :position, :estimate, :error, :id, :answers_count

  def initialize(id, antennae_count = 16)
    @id = id.to_s
    @position = Point.new(*id_to_position)
    @estimate = {}
    @error = {}
    @answers = {
        :a => {:average => {}, :adaptive => {}},
        :rss => {:average => {}, :detailed => {}},
        :rr => {:average => {}}
    }
    @answers_count = 0

    1.upto(antennae_count) do |antenna|
      @answers[:a][:average][antenna] = 0
      @answers[:a][:adaptive][antenna] = 0
    end
  end



  class << self
    def tag_ids
      prefix = '00000000000000000000'
      tags_ids = []

      letters = ('A'..'F')
      numbers = (1..12)

      letters.each do |letter|
        2.times do |time|
          numbers.each do |number|
            number = "%02d" % number
            letter_combination = "0" + letter.to_s if time == 0
            letter_combination = letter.to_s * 2 if time == 1
            tags_ids.push(prefix.to_s + letter_combination.to_s + number.to_s)
          end
        end
      end
      tags_ids
    end
  end




  private


  # 000000000000000000000F02 => [270, 110]
  def id_to_position

    x_code = @id[-4..-3]
    y_code = @id[-2..-1]

    x_code_number = tag_x_code_to_number(x_code)
    y_code_number = y_code.to_i - 1

    number_to_centimeters = lambda {|number| 30 + (number) * 40}
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