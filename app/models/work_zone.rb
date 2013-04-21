class WorkZone
  attr_accessor :width, :height, :antennae

  def initialize(x = 500, y = 500, antennae_count = 16)
    @width = x
    @height = y

    @antennae = {}
    1.upto(antennae_count) do |number|
      @antennae[number] = Antenna.new number
    end
  end
end