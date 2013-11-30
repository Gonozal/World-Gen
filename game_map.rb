class GameMap
  attr_accessor :pois, :size, :space, :field_cutoff, :field_max, :stack

  def initialize(params = {})
    self.pois = []
    self.size = 800
    self.space = 10
    self.field_max = 100.0
    pois << init_map
  end

  def field_magnitude(position)
    pois.map do |poi|
      poi.influence_magnitude(position)
    end.inject(0, :+)
  end

  def window_size
    size + 2 * space
  end

  private
  def init_map
    poi = PointOfInterest.new(location: Vector[400, 400], size: 2, name: "Some City")
    poi.name = "Some City"
    poi.location = Vector[400, 400]
    poi.influences << Influence.new(parent: poi, multiplier: 200, type: :protection)
    poi
  end
end
