module WorldGen
  class River
    attr_accessor :path, :game_map, :name

    def initialize(params)
      params.each do |key, val|
        send "#{key}=".to_sym, val if respond_to? key
      end
      self.path = SvgPath.new({path: path, game_map: game_map, scale: params[:scale]})
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
