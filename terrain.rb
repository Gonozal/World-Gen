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
      set_costs
    end

    def costs
      @cost ||= case self.type
      when :mountain then [200, 180, 160, 140]
      when :lake then [nil, 150, 125, 115]
      when :swamp then [200, 165, 140, 120]
      when :sea then [nil, 100, 100, 100]
      when :forest then [160, 140, 120, 100]
      end
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
      rect = offsets.last.bounding_rectangle
      (rect[0][0]..rect[1][0]).each do |x|
        (rect[0][1]..recht[1][1]).each do |y|
          [polygon, *offsets].each_with_index do |p, key|
            if p.contains? Vector[x, y]
              game_map.a_star_map[x][y] = costs[key]
            end
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
