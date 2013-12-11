module WorldGen
  class Road
    attr_accessor :start, :goal, :path, :astar, :game_map
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
