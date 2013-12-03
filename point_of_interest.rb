module WorldGen
  class PointOfInterest < Locateable
    # name: String: name of the POI
    # location: Vector[Integer, Integer]: with 2 coordinates (x and y)
    # :influences: Array[Influence]: with 0-n influence instances
    # radius: Float: diameter of the POI in km
    # radius: Float: diameter of the POI in km as displayed on the map
    # area: Float: area of the POI in ha (hectare, 10,000 square meters)
    attr_accessor :name, :influences, :radius
    def initialize(params = {})
      raise ArgumentError, "location" unless valid_params? params

      super
      self.influences = []
    end

    def display_name
      if Town === self
        name_suffix = " (#{type.to_s.upcase[0]}#{(capital)? "-C": ""})"
      end
      if map_radius > 0.5
        "'#{name}#{name_suffix}'"
      else
        "'#{name_suffix}'"
      end
    end

    def influence_magnitude(position)
      influences.map do |influence|
        influence.magnitude(position)
      end.inject(0, :+)
    end

    def symbol
      if Town === self
        if capital
          :star
        elsif map_radius < 0.5
          :dot
        else
          case self.type
          when :metropolis then :rectangle
          when :city then :hollow_rectangle
          when :town then :circle
          when :village then :hollow_circle
          end
        end
      end
    end

    def draw?
      range = ((0 - map_reach)..(game_map.canvas.size + map_reach))
      map_radius > 0.3 and map_location.select{ |i| range.include? i}.size == 2
    end

    # include town in drawn map even if it is this far away
    def map_reach
      if Town === self
        supporting_radius
      else
        0
      end
    end

    private
  end
end
