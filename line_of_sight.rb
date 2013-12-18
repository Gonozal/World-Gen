module WorldGen
  class LineOfSight
    attr_accessor :start, :goal, :terrain

    def initialize(params = {})
      self.start = Vector[*params.fetch(:start, [21, 495])]
      self.goal = Vector[*params.fetch(:goal, [24, 491])]

      # self.start = Vector[*params.fetch(:start, [495, 31])]
      # self.goal = Vector[*params.fetch(:goal, [484, 15])]
      self.terrain = params.fetch(:terrain, Array.new(804){Array.new(804, 100)})
      unless terrain.present?
        raise ArgumentError, "LineOfSight needs terrain on initialisation"
      end
      go

      puts "\n round 2"
      self.start = Vector[start[1], start[0]]
      self.goal = Vector[goal[1], goal[0]]
      go
    end

    def go
      v = goal - start
      g = goal
      s = start

      # if dx > dy.. what the heck, switch x and y, EVERYWHERE!
      if v[0].abs < v[1].abs
        v = Vector[v[1], v[0]]
        g = Vector[goal[1], goal[0]]
        s = Vector[start[1], start[0]]
        self.terrain = terrain.transpose # <---- switch x and y indices of cost matrix!!
      end

      # From here it's line 1++ from the paper
      cost = 0
      sx = (v[0] == 0)? 0 : v[0] / v[0].abs
      sy = (v[1] == 0)? 0 : v[1] / v[1].abs

      dx = 2 * v[0].abs
      dy = 2 * v[1].abs

      return true if dx == 0 and dy == 0

      # line 8-35  of paper
      t = (dy - dx) / 2
      p = (dy + dx) / 2
      w = 0.0
      e = 0.0
      x, y = s[0], s[1] # use potentially switched start and end vectors
      cost = 0 + 0.5 * terrain[x][y]
      until x == g[0]
        if e > t
          x, y = x + sx, y
          e = e - dy
          if p + e < dy
            w = (p + e) / dy
            cost += w * terrain[x][y]
          else
            cost += terrain[x][y]
          end
        elsif e < t
          x, y = x, y + sy
          e = e + dx
          cost += (1 - w) * terrain[x][y]
        else
          x, y = x + sx, y + sy
          e = e + dx - dy
          cost += terrain[x][y]
        end
      end
      cost -= 0.5 * terrain[x][y]
      cost = cost * (dx ** 2 + dy ** 2) ** 0.5 / dx if dx != 0
      puts cost

      cost
    end
  end
end
