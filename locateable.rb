module WorldGen
  class Locateable
    attr_accessor :name, :location, :area, :game_map

    def initialize(params = {})
      params.each do |key, val|
        send "#{key}=".to_sym, val
      end
    end

    def map_radius
      radius / game_map.meter_per_pixel
    end

    def map_location
      (location - game_map.offset) * game_map.zoom
    end

    # Vector math to get Distance and Direction
    def distance position
      (parent.location - position).magnitude
    end

    def direction position
      (parent.location - position).normalize
    end

    private
    def valid_params? params
      (params.has_key? :location and params[:location].present?) or
        (params.has_key? :vertices and params[:vertices].present?)
    end
  end
end
