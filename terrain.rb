module WorldGen
  class Terrain < Locateable
    attr_accessor :type, :vertices, :influences

    def initialize(params = {})
      self.vertices = []
      params.each do |key, val|
        send "#{key}=".to_sym, val
      end

      self.influences = []
    end

    # transform type to color that can be used by RMagick
    def map_color
      case self.type
      when :mountains then "brown"
      when :sea then "blue"
      end
    end

    # Offset and scale vertice coordinates for map rendering
    def map_vertices
      vertices.map do |v|
        (v - game_map.offset) * game_map.zoom
      end
    end

    # Calculates the distance from self (polygon) to a vector or POI
    def distance position
      # If POI is given instead of location, get location first
      position = position.location if PointOfInterest === position
      # Set a ridiculous min distance. and initialize vectors for loop. Any shortcuts?
      min_dist = 9999999999; c_v = Vector[0, 0]; o_v = Vector[0, 0]

      # Iterate over every edge-point (vertex)
      vertices.each_with_index do |v, i|
        v2 = Vector[*v]
        c_v = v2
        if i == 0  # We need 2 vertices to draw a line from which to calc distance
          o_v = v2
          next
        end

        r = ((c_v - o_v) * (position - o_v)) / (position - o_v).magnitude

        if r < 0 then dist = (position - o_v).magnitude
        elsif r > 1 then dist = (c_v - position).magnitude
        else dist = (position - o_v).magnitude ** 2 - r * (c_v - o_v).magnitude ** 2
        end

        min_dist = [dist, min_dist].min
        o_v = v2
      end
      min_dist
    end
  end
end
