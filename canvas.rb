module WorldGen
  class Canvas
    attr_accessor :game_map, :window
    attr_accessor :image, :blank_image
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
      self.blank_image = image.copy
    end

    # Returns window-relative min and max position of canvas
    def boundaries
      @boundaries ||= ((0 + padding)..(size + padding))
    end

    # Replaces old image with a blank one
    def reset
      self.image = blank_image.copy
    end

    # Draws circle around a poi representing cultivated land
    def draw_supporting_land poi
      cp = Magick::Draw.new
      cp.stroke("transparent").fill("green").opacity(0.2)
      params = {center: poi.map_location, radius: poi.supporting_radius * game_map.zoom}
      cp.circle(*circle(params))
      cp.draw image
    end

    # Draws a POI (town, outpost..) specific symbol on the map (star, rectangle, cross..)
    def draw_poi poi
      cp = Magick::Draw.new
      cp.stroke("black").stroke_width(1).opacity(1)
      params = { center: poi.map_location, radius: [poi.map_radius, 1].max }
      case poi.symbol
        when :dot then cp.point(params[:center][0], params[:center][1])
        when :star then cp.polygon(*star(params))
        when :rectangle then cp.rectangle(*rectangle(params))
        when :hollow_rectangle
          cp.fill_opacity(0).rectangle(*rectangle(params)).fill_opacity(1)
        when :circle then cp.circle(*circle(params))
        when :hollow_circle
          cp.fill_opacity(0).circle(*circle(params)).fill_opacity(1)
      end

      puts "#{poi.name}: #{game_map.terrain.last.distance poi}"

      draw_supporting_land poi if Town === poi

      cp.text_align(Magick::CenterAlign).stroke("transparent").pointsize(9)
      cp.text poi.map_location[0], poi.map_location[1] + poi.map_radius + 12,
              poi.display_name
      cp.draw image
    end

    # Draws Terrain objects to map, color defined in Terrain Class
    def draw_terrain terrain
      cp = Magick::Draw.new
      cp.stroke("black").fill(terrain.map_color).stroke_width(1).opacity(1)
      cp.polygon(*terrain.map_vertices.map{|v| v.to_a}.flatten)
      cp.draw image
    end

    # Draws a distance marker on the bottom left (part of the legend)
    def draw_distance_marker
      cp = Magick::Draw.new
      cp.fill("black").stroke("black").stroke_width(1).opacity(1)
      cp.text_align(Magick::CenterAlign).pointsize(9)

      y = 770; x = 520; x_end = x
      steps_km = (2.5 / game_map.zoom).floor
      steps_px = (steps_km.to_f / game_map.meter_per_pixel * 1000).to_i

      # Draw rectangles representing distances and distance numbers
      6.times do |i|
        ((i.odd?)? cp.fill("transparent") : cp.fill("black")).stroke("black")
        x_end = x + steps_px
        cp.rectangle(x,y, x_end, y+10)
        cp.fill("black").stroke("transparent").text x_end, y - 9, "'#{steps_km * (i + 1)}'"
        x = x + steps_px
      end

      cp.text(x_end + 25, y + 8, "'kilometer'")
      cp.draw image
    end

    # Draws grid on the canvas to make navigation easier
    def draw_grid
      grid = Magick::Draw.new
      grid.stroke("black").stroke_width(1).opacity(0.5)
      (grid_pieces + 1).times do |i|
        if game_map.zoom > 0.0625
          grid.stroke_width(3) if i % 4 == 0
          grid.opacity(0.6) if i == 0
          grid.stroke_width(1) if i % 4 == 1
          grid.opacity(0.6) if i == 1
        else
          grid.opacity(0.4) if i == 0
        end

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

    # Returns coordinates (TL, BR) for a rectangle given a center position and radius
    def rectangle(params)
      [ (params[:center][0] - params[:radius]).round,
        (params[:center][1] + params[:radius]).round,
        (params[:center][0] + params[:radius]).round,
        (params[:center][1] - params[:radius]).round ]
    end

    # Returns coordinates (Cntr, point on circle) for a circle for use with RMagick
    def circle(params)
      [ (params[:center][0]).round,
        (params[:center][1]).round,
        (params[:center][0] + params[:radius]).round,
        (params[:center][1]).round ]
    end
  end
end
