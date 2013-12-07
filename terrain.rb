module WorldGen
  class Terrain < Locateable
    attr_accessor :type, :influences, :game_map
    attr_accessor :polygon, :offsets

    def initialize(params = {})
      self.influences = []
      self.offsets = []
      multiplier = params.fetch(:mult, 16)
      params[:vertices] = params[:vertices].map{ |v| v * multiplier} unless multiplier == 1
      params.each do |key, val|
        send "#{key}=".to_sym, val if respond_to? "#{key}=".to_sym
      end
      add_polygons(params)
    end

    def costs
      @cost ||= case self.type
      when :mountain then [200, 180, 160, 140]
      when :lake then [255, 150, 125, 115]
      when :swamp then [200, 165, 140, 120]
      when :sea then [255, 100, 100, 100]
      when :forest then [160, 140, 120, 100]
      end
    end

    def cost_color n
      cost = costs[n]
      "rgb(#{255-cost}, #{255-cost}, #{255-cost})"
    end

    def offset_widths
      @offset_widths ||= case self.type
      when :sea then []
      when :forest then [48, 96]
      when :swamp then [64]
      else [32, 64, 96]
      end
    end

    def set_cost
      return nil if type == :lake or type == :sea
      (type == :sea)? set_line_cost : set_polygon_cost
    end

    def set_polygon_cost
      rect = ((offsets.size > 0)? offsets.last : polygon).bounding_rectangle
      ((rect[0][0] / 16)..(rect[1][0] / 16)).each do |x|
        ((rect[0][1] / 16)..(rect[1][1] / 16)).each do |y|
          [polygon, *offsets].reverse.each_with_index do |p, key|
            if p.contains? Vector[x * 16, y * 16]
              game_map.a_star_map[x][y] = costs[offsets.length - key]
            end
          end
        end
      end
    end

    def set_line_cost
      [polygon.vertices, polygon.vertices.first].flatten.each_cons(2) do |p1, p2|
        p1 /= 16
        p2 /= 16

        v = p2 - p1
        n_max = v.to_a.max
        m_max = v.to_a.min
        if v[0] > v[1]
          v[0].times do |n|
            x = p1[0] + n
            y = p1[1] + n * m_max / n_max
            game_map.a_star_map[x][y] = nil
            game_map.a_star_map[x][y + 1 ] = nil if y + 1 < 803
            game_map.a_star_map[x + 1][y] = nil if x + 1 < 803
          end
        else
          v[1].times do |n|
            y = p1[1] + n
            x = p1[0] + n * m_max / n_max
            game_map.a_star_map[x][y] = nil
            game_map.a_star_map[x][y + 1 ] = nil if y + 1 < 803
            game_map.a_star_map[x + 1][y] = nil if x + 1 < 803
          end
        end
      end
    end

    def add_polygons(p)
      self.polygon = Polygon.new({
        parent: self, 
        vertices: p[:vertices],
        game_map: p[:game_map]
      })
    end

    def add_offsets
      hashes = []
      offset_widths.each_with_index do |v, key|
        opacity = 0.3
        vertices = self.polygon.offset(v)
        hashes << { parent: self, vertices: vertices, game_map: game_map, opacity: opacity }
      end

      hashes.each do |param|
        self.offsets << Polygon.new(param)
      end
    end
  end
end
