module WorldGen
  class River
    attr_accessor :path, :game_map, :name

    def initialize(params)
      params.each do |key, val|
        send "#{key}=".to_sym, val if respond_to? key
      end
      self.path = SvgPath.new({path: path, game_map: game_map, scale: params[:scale]})
    end

    def colors
      mult = (game_map.zoom == 1)? 2 : 1
      [
        [1 * mult, "rgba(0,0,255,1)"]
      ]
    end

    def costs
      mult = (game_map.zoom == 1)? 2 : 1
      [
        [32 * game_map.zoom, "rgba(100,100,100,0.4)"],
        [1 * mult, "rgba(80,80,80,1)"]
      ]
    end

    def land_values
      mult = (game_map.zoom == 1)? 2 : 1
      [
        [400 * game_map.zoom, "rgba(255,255,255,0.04)"],
        [250 * game_map.zoom, "rgba(255,255,255,0.04)"],
        [150 * game_map.zoom, "rgba(255,255,255,0.04)"],
        [80 * game_map.zoom, "rgba(255,255,255,0.04)"],
        [50 * game_map.zoom, "rgba(255,255,255,0.08)"],
        [1 * mult, "rgba(0,0,0,1)"]
      ]
    end

    def path
      @path.to_s
    end

    def draw?
      @path.draw?
    end

    def map_path
      @path.map_path
    end

    def map_courve
      # (courve - game_map.offset) * game_map.zoom
    end
  end
end
