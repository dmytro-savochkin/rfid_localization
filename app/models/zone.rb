class Zone
  #POWERS_TO_SIZES = {
  #  19 => [125, 80],
  #  20 => [125, 80],
  #  21 => [125, 80],
  #  22 => [125, 80],
  #  23 => [125, 80],
  #  24 => [125, 80],
  #  25 => [125, 80],
  #  26 => [125, 80],
  #  27 => [125, 80],
  #  28 => [125, 80],
  #  29 => [125, 80],
  #  30 => [140, 90],
  #  :sum => [125, 80]
  #}

	POWERS_TO_SIZES = {
			19 => [125, 80],
			20 => [125, 80],
			21 => [155, 100],
			22 => [185, 120],
			23 => [215, 140],
			24 => [245, 160],
			25 => [285, 180],
			26 => [315, 200],
			27 => [345, 220],
			28 => [375, 240],
			29 => [405, 260],
			30 => [490, 310],
			:sum => [125, 80]
	}


  attr_reader :number, :coordinates, :size


  def initialize(number)
    @number = number
    @coordinates = Antenna.new(number.to_i).coordinates
    @size = 120.0
  end


  def self.distance_score_for_zones(zone1, zone2)
    return 0 if zone1.number == zone2.number
    shortest_distance = 120
    distance = Point.distance(zone1.coordinates, zone2.coordinates)
    distance.to_f / shortest_distance
  end

  def self.number_from_point(point)
    Antenna.number_from_point(point)
  end



end