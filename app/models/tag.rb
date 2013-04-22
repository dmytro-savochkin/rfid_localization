class Tag
  attr_accessor :answers, :estimate, :position

  def initialize(id, antennae_count = 16)
    @id = id.to_s
    @position = Point.new *id_to_position
    @estimate = nil
    @answers = {
        :a => {:average => {}},
        :rss => {:average => {}, :detailed => {}},
        :rr => {:average => {}}
    }

    1.upto(antennae_count) {|antenna| @answers[:a][:average][antenna] = 0}
  end




  private


  # 000000000000000000000F02 => [270, 110]
  def id_to_position

    x_code = @id[-4..-3]
    y_code = @id[-2..-1]

    x_code_number = tag_x_code_to_number(x_code)
    y_code_number = y_code.to_i

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