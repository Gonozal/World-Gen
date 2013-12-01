class Canvas
  attr_accessor :game_map, :window
  attr_accessor :image
  attr_accessor :grid_pieces
  attr_accessor :size, :padding

  def initialize(params = {})
    self.size = 804
    self.padding = 10
    self.grid_pieces ||= 12

    params.each do |key, val|
      send "#{key}=".to_sym, val
    end

    self.image = Magick::Image.new(size + 1, size + 1)
  end

  def draw_poi poi
    cp = Magick::Draw.new
    cp.stroke("black").stroke_width(1).opacity(1)
    params = {center: poi.location, radius: poi.map_radius}

    case poi.symbol
      when :star then cp.polygon(*star(params))
      when :rectangle then cp.rectangle(*rectangle(params))
      when :hollow_rectangle
        cp.fill_opacity(0).rectangle(*rectangle(params)).fill_opacity(1)
      when :circle then cp.circle(*circle(params))
      when :hollow_circle
        cp.fill_opacity(0).circle(*circle(params)).fill_opacity(1)
    end

    cp.text_align(Magick::CenterAlign).stroke("transparent").pointsize(9)
    cp.text poi.location[0], poi.location[1] + poi.map_radius + 10, poi.display_name
    cp.draw image
  end

  def draw_grid
    grid = Magick::Draw.new
    grid.opacity 0.25
    (grid_pieces + 1).times do |i|
      pos = size / grid_pieces * i
      grid.line 0, pos, size, pos
      grid.line pos, 0, pos, size
    end
    grid.draw image
  end

  private
  # (points: Integer) -> Array(2n+Integer)
  # Gives the coordinates to draw a star
  def star(params)
    coordinates = []
    steps = params.fetch(:points, 5) * 2
    steps.times do |i|
      distance = (i.even?)? (0.4 * params[:radius]) : params[:radius]
      coordinates << (params[:center][0] + distance * Math.sin(2 * i * Math::PI / steps))
      coordinates << (params[:center][1] + distance * Math.cos(2 * i * Math::PI / steps))
    end
    coordinates.map { |c| c.round }
  end

  def rectangle(params)
    [ (params[:center][0] - params[:radius]).round,
      (params[:center][1] + params[:radius]).round,
      (params[:center][0] + params[:radius]).round,
      (params[:center][1] - params[:radius]).round ]
  end

  def circle(params)
    [ (params[:center][0]).round,
      (params[:center][1]).round,
      (params[:center][0] + params[:radius]).round,
      (params[:center][1]).round ]
  end
end
