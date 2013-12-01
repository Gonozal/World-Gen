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

  def draw_grid(params)
    11.times do |i|
      pos = size / 10 * i
      params[:draw].line 0, pos, gm.size, pos
      params[:draw].line pos, 0, pos, gm.size
    end
    parans[:draw].draw params[:img]
  end

  def self.default_drawer
    draw = Magick::Draw.new
    draw.stroke 'black'
    draw.fill 'black'
    draw.opacity 1
    draw.stroke_width 1
    draw
  end

  private
  def init_map
    poi = Town.new(
      location: Vector[400, 400], 
      size: 2, 
      name: "Some City", 
      population: 25000,
      alignments: [:lawful_good, :good]
    )
    poi
  end
end
