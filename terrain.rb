require 'polygon_math'
module WorldGen
  class Terrain < Locateable
    include PolygonMath
    attr_accessor :type, :influences, :game_map

    def initialize(params = {})
      self.vertices = []
      self.influences = []
      params.each do |key, val|
        send "#{key}=".to_sym, val
      end

    end

    # transform type to color that can be used by RMagick
    def map_color
      case self.type
      when :mountains then "brown"
      when :sea then "blue"
      end
    end
  end
end
