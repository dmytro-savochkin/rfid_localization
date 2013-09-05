class PointStepper
  attr_reader :step

  def initialize(step)
    @step = step.to_i
  end

  def each
    (TagInput::START..(WorkZone::WIDTH-TagInput::START)).step(@step).each do |x|
      (TagInput::START..(WorkZone::HEIGHT-TagInput::START)).step(@step).each do |y|
        yield Point.new(x, y)
      end
    end
  end
end