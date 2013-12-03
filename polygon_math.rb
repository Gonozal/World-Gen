module PolygonMath
  # Bounding Rectangle: [Vector[tl_x, tl_y], Vector[br_x, br_y]]: minimum bounding rectangle
  # Vertices: [Vector[x1, y1], Vector[x2, y2], ... , Vector[xn, yn]]: defining points
  attr_accessor :vertices, :bounding_rectangle
  # Offset and scale vertice coordinates for map rendering
  def map_vertices
    vertices.map do |v|
      (v - game_map.offset) * game_map.zoom
    end
  end

  # Checks if a point is inside the polygon shape of the terrain, returns true if so
  def contains? position
    # If POI is given instead of location, get location first
    position = position.location if PointOfInterest === position

    # Use the raycasting technique to determine if point is inside polygon
    # We are in 2D, which makes it easier.
    # We can also choose the direction of the ray, which makes it almost trivial
    # (Choose ray paralell to x-achis
    pos_x = position[0]
    intersections = 0

    vertices.each_cons(2) do |vertices|
      x1 = vertices[0][0]
      x2 = vertices[1][0]
      if (x1 < pos_x and pos_x < x2) or (x1 > pos_x and pos_x > x2)
        intersections += 1
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
end
