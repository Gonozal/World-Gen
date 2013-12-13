module WorldGen
  class Road
    attr_accessor :start, :goal, :path, :game_map
    def initialize(params)
      params.fetch(:mult, 16)
      self.start = params[:start] * params[:mult]
      self.goal = params[:end] * params[:mult]
      self.game_map = params[:game_map]
    end

    def map_path(mult = 1)
      self.path.map do |point|
        p = (point - game_map.offset) * game_map.zoom
        [p[0] * mult, p[1] * mult]
      end.flatten
    end

    def land_values
      rgb = 230 + rand(26)
      rgba = "rgba(#{rgb},#{rgb},#{rgb},0.08)"
      [
        [10 * game_map.zoom, rgba],
        [15 * game_map.zoom, rgba]
      ]
    end

    def town_influences
      [
        [960 * game_map.zoom, "rgba(255,255,255,1)"]
      ]
    end

    def city_influences
      [
        [1600 * game_map.zoom, "rgba(255,255,255,1)"],
        [960 * game_map.zoom, "rgba(0,0,0,1)"]
      ]
    end

    # returns distance and closest point on the path
    def distance
      min_dist = 9999999999
      path.each_cons(2) do |points|
        c_v, o_v = *points
        r = ((c_v - o_v) * (position - o_v)) / (position - o_v).magnitude

        if r < 0
          dist = [(position - o_v).magnitude, o_v]
        elsif r > 1
          dist = [(c_v - position).magnitude, c_v]
        else
          dist = (position - o_v).magnitude ** 2 - r * (c_v - o_v).magnitude ** 2
          dist = [dist, ov + r * (c_v - o_v)]
        end

        min_dist = [dist, min_dist].min
      end
      min_dist
    end


    def find_path
      astar = Astar.new
      t = Time.now
      params = {
        terrain: game_map.a_star_map,
        start: (start / 32).to_i * 2,
        goal: (goal / 32).to_i * 2,
        game_map: game_map
      }
      self.path = astar.do_quiz_solution(params)
      puts "pathfinding time from #{start} to #{goal}: #{Time.now - t}"
    end
  end
end
