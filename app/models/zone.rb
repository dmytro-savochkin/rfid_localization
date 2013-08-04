class Zone
  POWERS_TO_SIZES = {
    19 => [125, 80],
    20 => [125, 80],
    21 => [125, 80],
    22 => [125, 80],
    23 => [125, 80],
    24 => [125, 80],
    25 => [125, 80],
    26 => [125, 80],
    27 => [125, 80],
    28 => [125, 80],
    29 => [125, 80],
    30 => [125, 80],
    :sum => [125, 80]
  }


  attr_reader :number, :coordinates


  def initialize(number)
    @number = number
    @coordinates = Antenna.new(number.to_i).coordinates
  end


  def self.distance_score_for_zones(zone1, zone2)
    return 0 if zone1.number == zone2.number
    shortest_distance = 120
    distance = Point.distance(zone1.coordinates, zone2.coordinates)
    distance.to_f / shortest_distance
  end



end