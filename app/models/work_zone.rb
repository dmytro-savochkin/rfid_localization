class WorkZone
  WIDTH = 500
  HEIGHT = 500
  attr_accessor :width, :height, :antennae, :reader_power

  def initialize(reader_power, antennae_count = 16)
    @reader_power = reader_power
    @width = WIDTH
    @height = HEIGHT

    @antennae = {}
    1.upto(antennae_count) do |number|
      @antennae[number] = Antenna.new(number, Zone::POWERS_TO_SIZES[reader_power])
    end
  end
end