class GameMap
  attr_accessor :pois, :size, :field_cutoff, :field_max, :stack, :canvas

  def initialize(window)
    self.pois = []
    self.field_max = 100.0

    self.canvas = Canvas.new(game_map: self, window: window)
    pois << init_map
    pois.flatten!
  end

  def field_magnitude(position)
    pois.map do |poi|
      poi.influence_magnitude(position)
    end.inject(0, :+)
  end

  def window_size
    canvas.size + 2 * canvas.padding
  end

  private
  def init_map
    [
      Town.new(
        location: Vector[400, 400], 
        capital: true,
        name: "Baldurs Gate", 
        population: 150000,
        alignments: [:lawful_good, :good]
      ), Town.new(
        location: Vector[300, 100],
        name: "Random Metropolis",
        population: 25000
      ), Town.new(
        location: Vector[600, 100],
        name: "Random City",
        population: 15000
      ), Town.new(
        location: Vector[300, 400],
        name: "Random Town",
        population: 6500
      ), Town.new(
        location: Vector[500, 300],
        name: "Random Village",
        population: 350
      )
    ]
  end
end
