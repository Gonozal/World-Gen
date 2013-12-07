module WorldGen
  class Canvas
    attr_accessor :game_map, :window
    attr_accessor :image, :blank_image, :cost_image, :blank_cost_image
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
      self.cost_image = Magick::Image.new((size + 1), (size + 1)) do
        self.background_color = "rgb(155, 155, 155)"
      end
      self.blank_cost_image = cost_image.copy
      self.blank_image = image.copy
    end

    # Returns window-relative min and max position of canvas
    def boundaries
      @boundaries ||= ((0 + padding)..(size + padding))
    end

    # Replaces old image with a blank one
    def reset
      self.image = blank_image.copy
      self.cost_image = blank_cost_image.copy
    end

    # Draws circle around a poi representing cultivated land
    def draw_supporting_land poi
      cp = Magick::Draw.new
      cp.stroke("transparent").fill("green").opacity(0.2)
      if poi.map_supporting_radius > 0.6
        params = {center: poi.map_location, radius: poi.map_supporting_radius}
        cp.circle(*circle(params))
      else
        cp.point(*poi.map_location)
      end
      cp.draw image
    end

    def draw_pois
      return nil if game_map.visible_pois.empty?
      cp = Magick::Draw.new
      game_map.visible_pois.each do |poi|
        draw_poi poi, cp
      end
      cp.draw image
    end

    # Draws a POI (town, outpost..) specific symbol on the map (star, rectangle, cross..)
    def draw_poi(poi, cp)
      cp.stroke("black").stroke_width(1).opacity(1)
      params = { center: poi.map_location, radius: [poi.map_radius, 1].max }
      case poi.symbol
        when :dot then cp.point(*params[:center])
        when :star then cp.polygon(*star(params))
        when :rectangle then cp.rectangle(*rectangle(params))
        when :hollow_rectangle
          cp.fill_opacity(0).rectangle(*rectangle(params)).fill_opacity(1)
        when :circle then cp.circle(*circle(params))
        when :hollow_circle
          cp.fill_opacity(0).circle(*circle(params)).fill_opacity(1)
      end

      draw_supporting_land poi if Town === poi

      cp.text_align(Magick::CenterAlign).stroke("transparent").pointsize(9)
      cp.text poi.map_location[0], poi.map_location[1] + poi.map_radius + 12,
              poi.display_name unless poi.display_name.blank?
    end

    def draw_terrains(draw_type = :map)
      cp = Magick::Draw.new
      game_map.terrain.each do |terrain|
        draw_terrain terrain, cp, draw_type
      end
      if draw_type == :map
        cp.draw image
      elsif draw_type == :cost
        cp.draw cost_image
      end
    end

    def draw_roads(draw_type = :map)
      game_map.roads.each do |road|
        draw_road road, draw_type
      end if game_map.roads.any?
    end

    def draw_road(road, draw_type = :map)
      cp = Magick::Draw.new
      return nil if road.path.blank?
      path = road.map_path
      if draw_type == :cost
        cp.stroke("white").stroke_width(2).fill_opacity(0).stroke_opacity(0.2)
        cp.polyline(*road.map_path) if path.present?
      elsif draw_type == :map
        cp.stroke("brown").stroke_width(2).fill_opacity(0).stroke_opacity(1)
        cp.polyline(*road.map_path) if path.present?
      end
      if draw_type == :map
        cp.draw image
      elsif draw_type == :cost
        cp.draw cost_image
      end
    end

    def draw_costs
      return nil unless game_map.a_star_map.present?
      cp = Magick::Draw.new
      (0..400).each do |x|
        (400..803).each do |y|
          cost = game_map.a_star_map[x][y]
          if cost.present?
            cp.fill("rgba(#{250-cost}, 10, #{250-cost}, 1)") 
          else
            cp.fill("black")
          end
          cp.point(x, y)
        end
      end
      cp.draw image
    end

    # Draws Terrain objects to map, color defined in Terrain Class
    def draw_terrain(terrain, cp, draw_type = :map)
      polygons = []
      terrain.offsets.size.times do |i|
        polygons << terrain.offsets[terrain.offsets.size - 1 - i]
      end
      polygons << terrain.polygon

      polygons.each_with_index do |p, index|
        case draw_type
        when :map
          cp.stroke(p.stroke_color).fill(p.fill_color).stroke_width(1)
          cp.polygon(*p.map_vertices.map{|v| v.to_a}.flatten)
        when :cost
          n = polygons.size - index - 1
          cp.stroke("transparent").stroke_width(0).fill(terrain.cost_color n)
          cp.polygon(*p.map_vertices.map{|v| v.to_a}.flatten)
        else next
        end
      end
    end

    def draw_region region

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
