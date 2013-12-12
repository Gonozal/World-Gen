module WorldGen
  class GameMap
    attr_accessor :window, :detail_window, :canvas, :size
    attr_accessor :regions
    attr_accessor :zoom, :zoom_to, :zoom_from, :offset
    attr_accessor :a_star_map, :land_values
    attr_accessor :init_step

    def initialize(window)
      self.window = window
      self.init_step = 0
      self.zoom = 0.0625; self.zoom_to = [0, 0]; self.offset = Vector[0, 0]

      self.canvas = Canvas.new(game_map: self, window: self.window)
      self.detail_window = DetailWindow.new(game_map: self, window: self.window)
    end

    def pois
      regions.map {|region| region.pois }.flatten
    end

    def visible_pois
      regions.map {|region| region.visible_pois }.flatten
    end

    def terrain
      regions.map {|region| region.terrain }.flatten
    end

    def roads
      regions.map {|region| region.roads }.flatten
    end

    def rivers
      regions.map {|region| region.rivers }.flatten
    end

    def sorted_pois
      regions.map {|region| region.pois}.flatten.sort {|a, b| a.population <=> b.population}
    end

    def gradually_initialize
      return nil if init_step > 6
      case init_step
      when 0
        self.regions = init_region
        regions.each do |region|
          region.initialize_imports
        end
      when 1
        regions.each do |region|
          region.after_initialize
        end
        window.redraw_map
      end
      self.init_step += 1
    end

    # Creates a 2d-Array (x and y) with terrain costs from canvas.cost_image
    # Obviously requires a call to create the image first
    def set_terrain_costs
      raise RuntimeError "Requires cost image" if canvas.images[:cost].blank?
      size = 804
      self.a_star_map = Array.new(size){Array.new(size, 100)}
      size.times do |x|
        size.times do |y|
          cost = (255 - canvas.images[:cost].pixel_color(x, y).red / 257).round
          a_star_map[x][y] = cost
        end
      end
    end

    def set_land_values
      raise RuntimeError "Requires land value image" if canvas.images[:land_value].blank?
      self.land_values = []
      land_value_i = []
      size = 264
      size.times do |x|
        size.times do |y|
          x_px = x * 3 + y % 3 + rand(0..10)
          y_px = y * 3 + 1 + rand(0..10)
          value = (canvas.images[:land_value].pixel_color(x_px, y_px).red / 257)
          road_value = (canvas.images[:road_distance].pixel_color(x_px, y_px).red / 257)
          next if value <= 156 or road_value < 200
          len = land_values.length
          i2 = land_value_i.index do |p|
            p <= value
          end || len
          land_values.insert(i2, [value, x_px, y_px])
          land_value_i.insert(i2, value)
        end
      end
    end


    # Creates and returns a blank canvas
    def new_canvas
      canvas.reset; canvas
    end

    # Creates and returns a blank detail window
    def new_detail_window
      detail_window.reset; detail_window
    end

    # Gets field magnitude for a position. TODO: rewrite to account for multiple types
    def field_magnitude(position)
      [ pois.map do |poi|
          poi.influence_magnitude(position)
        end.inject(0, :+), field_max].min / field_max
    end

    def window_size
      canvas.size + 2 * canvas.padding
    end

    def zoom_out
      case zoom
      when 0.0625
        return false
      when 0.25
        self.zoom = 0.0625
        self.zoom_to = [4, 4]
        self.offset = Vector[0, 0]
      when 1
        self.zoom = 0.25
        self.zoom_to = zoom_from
        self.offset = Vector.elements(zoom_to.map{|z| ([4, 44, z].sort[1]-4) * 67 }) * 4
      end
      true
    end

    def zoom_in(zoom_location)
      case zoom
      when 0.0625
        self.zoom = 0.25
        self.zoom_to = [(zoom_location[0] / 67).to_i * 4, (zoom_location[1] / 67).to_i * 4]
        self.offset = Vector.elements(zoom_to.map{|z| ([4, 44, z].sort[1]-4) * 67 }) * 4
      when 0.25
        self.zoom = 1
        self.zoom_from = zoom_to
        self.zoom_to = [
          zoom_to[0] + (zoom_location[0] / 67).to_i - 4,
          zoom_to[1] + (zoom_location[1] / 67).to_i - 4
        ]
        self.offset = Vector.elements(zoom_to.map{|z| ([1, 47, z].sort[1]-1) * 67 }) * 4
      when 1
        return false
      end
      return true
    end

    def meter_per_pixel
      62.5 / zoom
    end

    def init_region
      [
        Region.new(
          name: "Cormyr",
          age: 1250,
          population: 14000000,
          game_map: self
        )
      ]
    end
  end
end
