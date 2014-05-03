class Integer
  def factorial
    return 1 if self.zero?
    1.upto(self).inject(:*)
  end
end