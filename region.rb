module WorldGen
  class Region
    attr_accessor :pois, :name, :population, :age, :game_map
    def initialize(params = {})
      self.vertices = []
      self.influences = []
      params.each do |key, val|
        send "#{key}=".to_sym, val
      end
    end
  end
end
