module WorldGen
  class River
    attr_accessor :path, :game_map, :name

    def initialize(params)
      params.each do |key, val|
        send "#{key}=".to_sym, val
      end
      self.path = SvgPath.new({path: params[:path]})
    end

    def path
      @path.to_s
    end

    def map_courve
      # (courve - game_map.offset) * game_map.zoom
    end
  end
end
