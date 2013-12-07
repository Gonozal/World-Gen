module WorldGen
  class Polygon
    # Bounding Rectangle: [Vector[tl_x, tl_y], Vector[br_x, br_y]]: minimum bounding rect
    # Vertices: [Vector[x1, y1], Vector[x2, y2], ... , Vector[xn, yn]]: defining points
    attr_accessor :vertices, :bounding_rectangle, :game_map, :opacity, :parent

    def initialize(params)
      params.each do |key, val|
        send "#{key}=".to_sym, val if respond_to? "#{key}=".to_sym
      end
      self.bounding_rectangle = set_bounding_rectangle
      self.opacity ||= 1
    end

    def fill_color
      case parent.type
      when :mountain then "rgba(139, 69, 19, #{opacity})"
      when :lake then "rgba(15, 255, 240, #{opacity})"
      when :swamp then "rgba(107, 142, 35, #{opacity})"
      when :sea then "rgba(10, 10, 128, #{opacity})"
      when :forest then "rgba(34, 139, 34, #{opacity})"
      end
    end

    def stroke_color
      case opacity
      when 1 then "rgba(0, 0, 0, 0.6)"
      else "rgba(0, 0, 0, 0.3)"
      end
    end

    # Offset and scale vertice coordinates for map rendering
    def map_vertices(mult = 1)
      vertices.map do |v|
        (v - game_map.offset) * game_map.zoom * mult
      end
    end

    def map_offset(delta)
      offset(delta).map do |v|
        (v - game_map.offset) * game_map.zoom
      end
    end

    # Checks if a point is inside the polygon shape of the terrain, returns true if so
    def contains? position
      # If POI is given instead of location, get location first
      position = position.location if PointOfInterest === position

      x = position[0]
      y = position[1]

      # Use the raycasting technique to determine if point is inside polygon
      # We are in 2D, which makes it easier.
      # We can also choose the direction of the ray, which makes it almost trivial
      # (Choose ray paralell to x-achis
      intersections = 0

      [vertices, vertices.first].flatten.each_cons(2) do |v1, v2|
        # Check if we are inside bounding recangle of 2 vertices
        v1x = v1[0]
        v1y = v1[1]
        v2x = v2[0]
        v2y = v2[1]
        if (v1y < y and y <= v2y) or (v1y >= y and y > v2y)
          # check if we are LEFT of or onthe line from v1 to v2 is at this x coordinate
        cp.polygon(*p.map_vertices.map{|v| v.to_a}.flatten)
          vx = v2x - v1x
          vy = v2y - v1y
          if (x <= v1x and x < v2x)
            intersections +=1
          elsif x >= v1x and x > v2x
            next
          else
            x_line = v1x + vx * (y - v1y) / vy
            if vy == 0 or vx == 0 or x < x_line
              intersections += 1
            end
          end
        end
      end
      return intersections.odd?
    end

    # Calculates the distance from self (polygon) to a vector or POI
    def distance position
      return -1 if contains? position
      # If POI is given instead of location, get location first
      position = position.location if PointOfInterest === position
      # Set a ridiculous min distance. and initialize vectors for loop. Any shortcuts?
      min_dist = 999999999

      # Iterate over every edge-point (vertex)
      vertices.each_cons(2) do |vertices|
        c_v = vertices[0]
        o_v = vertices[1]

        r = ((c_v - o_v) * (position - o_v)) / (position - o_v).magnitude

        if r < 0 then dist = (position - o_v).magnitude
        elsif r > 1 then dist = (c_v - position).magnitude
        else dist = (position - o_v).magnitude ** 2 - r * (c_v - o_v).magnitude ** 2
        end

        min_dist = [dist, min_dist].min
      end
      min_dist
    end

    def set_bounding_rectangle
      min_x = min_y = 999999
      max_x = max_y = 0
      vertices.each do |v|
        min_x = [min_x, v[0]].min
        min_y = [min_y, v[1]].min
        max_x = [max_x, v[0]].max
        max_y = [max_y, v[1]].max
      end
      self.bounding_rectangle = [Vector[min_x, min_y], Vector[max_x, max_y]]
    end

    def random_point_inside
      candidate_x = (bounding_rectangle[0][0]..bounding_rectangle[1][0])
      candidate_y = (bounding_rectangle[0][1]..bounding_rectangle[1][1])
      return Vector[candidate_x, candidate_y] if contains? Vector[candidate_x, candidate_y]
    end


    ####################################################
    ####               Offset Polygon                ###
    ####                  Functions                  ###
    ####################################################

    # Get the orientation of a polygon
    # Pick "bottom left" corner vertex (and adjacent oes)
    # determine orientation matrix of this sub-polygon (which is guaranteed to be convex)
    def orientation
      p1, p2, p3 = *convex_sub_polygon
      det = (p2[0]-p1[0])*(p3[1]-p1[1]) - (p3[0]-p1[0])*(p2[1]-p1[1])
      @orientation ||= (det < 0)? 1 : -1
    end

    # Returns a set of 3 points along a convex subsection of the polygon
    def convex_sub_polygon
      subsets = []
      vertices.each_cons(3) do |p1, p2, p3|
        subsets << [p2, [p1, p2, p3]]
      end
      subsets.sort.first.last
    end

    # delta: Integer                              -- Offset amount
    def offset(delta, dist = 1.5)
      # set delta according to polygon direction, set veriables for first and last p/l
      delta = delta * orientation
      p_first, p_last = nil; offset_lines = []
      l_first, l_last = nil; offset_points = []
      refined_points = []

      # Offset lines between 2 consecutive vertices out by delta
      vertices.each_cons(2) do |p1, p2|
        p_first ||= p1; p_last = p2  # save first and last vector for final line
        offset_lines << offset_line(p1, p2, delta)
      end
      offset_lines << offset_line(p_last, p_first, delta)

      # Calculate intersections between adjacent lines for new vertices
      offset_lines.each_cons(2) do |l1, l2|
        l_first ||= l1; l_last = l2  # save first and last vector for final intersection
        offset_points << line_intersection(l1, l2)
      end
      offset_points.insert(0, line_intersection(l_first, l_last))

      # Smooth corners of very acute angles
      offset_points.each_with_index do |p, key|
        v = p - vertices[key]
        if v.magnitude > (dist * delta).abs
          p2 = vertices[key] + v.normalize * dist * delta.abs
          # normal vector for 2 vertices through a point dist*delta away
          cutoff_line = [p2, p2 + v.normal_vector]
          [-1, 0].each do |i|
            if key + i < 0
              n = offset_lines.size - 1
            elsif key + i >= offset_lines.size
              n = 0
            else
              n = key + i
            end
            refined_points << line_intersection(cutoff_line, offset_lines[n])
          end
        else
          refined_points << p
        end
      end
      refined_points
    end

    # calculate line intersections
    # most likely used to calculate new points for an offset polygon
    def line_intersection(l1, l2)
      x1 = l1[0][0]; x2 = l1[1][0]; x3 = l2[0][0]; x4 = l2[1][0]
      y1 = l1[0][1]; y2 = l1[1][1]; y3 = l2[0][1]; y4 = l2[1][1]

      denominator = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4)
      return false if denominator == 0
      dxy12 = (x1*y2 - y1*x2)
      dxy34 = (x3*y4 - y3*x4)
      x = (dxy12*(x3-x4) - (x1-x2)*dxy34) / denominator
      y = (dxy12*(y3-y4) - (y1-y2)*dxy34) / denominator
      WorldGen::Vector[x.round, y.round]
    end

    def offset_line(p1, p2, delta)
      v = p2 - p1
      n = v.normal_vector
      p_new = p1 + n.normalize * delta
      [p_new, p_new + v]
    end
  end
end
