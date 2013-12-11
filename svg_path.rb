module WorldGen
  class SvgPath
    attr_accessor :path, :parsed, :game_map, :scale, :bounding_box

    def initialize(params)
      params.each do |key, val|
        send "#{key}=".to_sym, val
      end
      parse unless path.blank?
      set_bounding_box unless path.blank?
      self
    end

    def set_bounding_box
      drawing = Magick::Draw.new
      canvas = Magick::Image.new(805, 805) { self.background_color = "white" }
      drawing.path map_path
      drawing.draw canvas
      canvas.trim!

      self.bounding_box = {
        x: canvas.page.x * 16,
        y: canvas.page.y * 16,
        width: canvas.columns * 16,
        height: canvas.rows * 16
      }
    end

    def point_in_bounding_box(point)
      (bounding_box[0][0]..bounding_box[1][0]).include? point[0] and
        (bounding_box[0][1]..bounding_box[1][1]).include? point[1]
    end

    def draw?
      return true if game_map.zoom == 0.0625
      w1 = h1 = 804 / game_map.zoom
      x1, y1 = *(game_map.offset - Vector[w1/2, w1/2])

      x2 = bounding_box[:x]
      y2 = bounding_box[:y]
      w2 = bounding_box[:width]
      h2 = bounding_box[:height]
      if x1 + w1 < x2 or x2 + w2 < x1 or y1 + h1 < y2 or y2 + h2 < y1
        return false
      else
        return true
      end
    end

    def parse
      self.parsed = path.scan(/(\w?)([0-9.,\- ]+)/).map do |e|
        [e[0], e[1].scan( /(-?[0-9.]+)|[, \-]?/ ).map{|se| se.first}.compact]
      end
    end

    def map_coordinate(coordinate, index, x, y, type = :absolute)
      if type == :relative
        x, y = 0.0, 0.0
      end

      # check if we are at the x or y coordinate or at a delimeter
      if index % 2 == 1         # y choordinate
        ((coordinate.to_f * 16 * scale - y) * game_map.zoom).round(2).to_s
      elsif index % 2 == 0      # x coordinate
        ((coordinate.to_f * 16 * scale - x) * game_map.zoom).round(2).to_s
      else                      # delimeter (should not happen..)
        coordinate
      end
    end

    def map_path
      offset_x = game_map.offset[0]
      offset_y = game_map.offset[1]
      new_path = parsed.map do |e|
        type = e[0]
        coordinates = e[1]
        if type == type.upcase
          c = coordinates.each_with_index.map do |coordinate, index|
            map_coordinate(coordinate, index, offset_x, offset_y, :absolute)
          end * ","
        else
          c = coordinates.each_with_index.map do |coordinate, index|
            map_coordinate(coordinate, index, offset_x, offset_y, :relative)
          end * ","
        end
        [type, c]
      end
      output = new_path.flatten.inject(""){|str, e| str << e}
      output
    end

    def to_s
      parsed.flatten.inject(""){|str, e| str << e}
    end
  end
end
