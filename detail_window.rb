module WorldGen
  class DetailWindow
    attr_accessor :game_map, :window
    attr_accessor :size
    attr_accessor :image, :blank_image
    def initialize(params = {})
      params.each do |key, val|
        send "#{key}=".to_sym, val
      end

      self.size = game_map.canvas.size / 2
      self.image = Magick::Image.new(size + 1, size + 1)
      draw_boundaries
      self.blank_image = image.copy
    end

    def reset
      self.image = blank_image.copy
    end

    private
    def draw_boundaries
      cp = Magick::Draw.new
      cp.stroke("black").fill("white").opacity(1)
      cp.rectangle(0,0, size,size)
      cp.draw image
    end
  end
end
