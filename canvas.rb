module WorldGen
  class Canvas
    attr_accessor :game_map, :window
    attr_accessor :image, :blank_image, :cost_image, :blank_cost_image
    attr_accessor :land_value_image, :blank_land_value_image
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
      self.land_value_image = Magick::Image.new((size + 1), (size + 1)) do
        self.background_color = "rgb(155, 155, 155)"
      end
      self.blank_land_value_image = land_value_image.copy
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
      self.land_value_image = blank_land_value_image.copy
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

    def draw_pois(draw_type = :map)
      return nil if game_map.visible_pois.empty? or draw_type == :cost
      cp = Magick::Draw.new
      case draw_type
      when :map
        game_map.visible_pois.each do |poi|
          draw_poi poi, cp
        end
        cp.draw image
      when :land_value
        game_map.pois.each do |poi|
          draw_poi_land_value poi, cp
        end
        cp.draw land_value_image
      end
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

    def draw_poi_land_value(poi, cp)
      # reset cp
      cp.stroke("rgba(0,0,0,0)").fill("rgba(0,0,0,1)").stroke_width(0)
      case poi
      when Town
        # Make sure no other town/city overlaps with existing ones
        params = { center: poi.map_location }
        cp.fill("rgba(0,0,0,0.4)")
        case poi.type
        when :village, :town
          # Lower land value around towns and villages (they don't have the draw of a city)
          params[:radius] = poi.map_supporting_radius * 1.5
          (params[:radius] > 1)? cp.circle(*circle(params)) : nil
        when :city, :metropolis
          # However, raise land value in a large radius (suburbs)
          rgb = poi.land_value_offset + 200
          cp.fill("rgba(#{rgb},#{rgb},#{rgb},0.08)")
          [1.5, 2, 2.25, 2.5, 2.67, 2.83, 3].each do |range|
            params[:radius] = poi.map_supporting_radius * (range)
            (params[:radius] > 1)? cp.circle(*circle(params)) : nil
          end
          # Lower land value around cities and metropilises a bit
          [0.75, 1].each do |range|
            params[:radius] = poi.map_supporting_radius * range
            (params[:radius] > 1)? cp.fill("rgba(0,0,0,0.3)").circle(*circle(params)) : nil
          end
        end
        params[:radius] = poi.map_radius * 1.5
        cp.fill("rgba(0,0,0,1)")
        (poi.map_radius < 1)? cp.point(*poi.map_location) : cp.circle(*circle(params))
      end
    end

    def draw_rivers(draw_type = :map)
      game_map.rivers.each do |river|
        draw_river river
      end
    end

    def draw_river river
      cp = Magick::Draw.new
      cp.stroke_width(2).fill("rgba(0,0,0,0)").stroke("rgba(0,0,255,1)")
      cp.path(river.path)
      cp.draw image
    end

    def draw_terrains(draw_type = :map)
      cp = Magick::Draw.new
      game_map.terrain.each do |terrain|
        draw_terrain terrain, cp, draw_type
      end
      case draw_type
      when :map
        cp.draw image
      when :cost
        cp.draw cost_image
      when :land_value
        cp.draw land_value_image
      end
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
        when :land_value
          cp.stroke(terrain.land_value_color(1)).stroke_opacity(0.12)
          polygon = terrain.polygon.map_vertices.map{|v| v.to_a}.flatten
          [2, 5, 10, 18, 25].each do |range|
            range = range * game_map.zoom / 0.0625
            cp.stroke_width(range).polygon(*polygon).fill("transparent")
          end
          cp.stroke_width(0).fill(terrain.land_value_color).opacity(1).stroke_opacity(0)
          cp.polygon(*polygon)
          break
        end
      end
    end

    def draw_roads(draw_type = :map)
      game_map.roads.each do |road|
        draw_road road, draw_type
      end if game_map.roads.any?
    end

    def draw_road(road, draw_type = :map)
      cp = Magick::Draw.new
      cp.stroke_width(2).fill_opacity(0)
      return nil if road.path.blank?
      case draw_type
      when  :cost
        path = road.map_path if road.path.present?
        cp.stroke("white").stroke_opacity(0.2).polyline(*path).draw cost_image
      when :map
        path = road.map_path if road.path.present?
        cp.stroke("brown").stroke_opacity(1).polyline(*path).draw image
      when :land_value
        path = road.map_path if road.path.present?
        cp.stroke("white").stroke_opacity(0.08)
        [5, 10, 15].each do |range|
          range = range * game_map.zoom / 0.0625
          cp.stroke_width(range).polyline(*path)
        end
        cp.stroke("rgba(10,10,10,1)").stroke_width(game_map.zoom / 0.0625).polyline(*path)
        cp.draw land_value_image
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
