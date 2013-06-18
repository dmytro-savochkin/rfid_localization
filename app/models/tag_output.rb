class TagOutput
  attr_accessor :estimate, :error, :id

  def initialize(tag, estimate)
    @id = tag.id.to_s
    @estimate = estimate
    @error = Point.distance(estimate, tag.position)
  end

end
