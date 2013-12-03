module WorldGen
  class GameMap
    attr_accessor :regions, :pois, :terrain
    attr_accessor :field_cutoff, :field_max, :zoom, :zoom_to
    attr_accessor :visible_pois
    attr_accessor :zoom, :zoom_to, :zoom_from
    attr_accessor :window, :offset, :size
    attr_accessor :detail_window, :canvas
    attr_accessor :a_star_map

    def initialize(window)
      self.pois, self.terrain = [];
      self.field_max = 200.0
      self.zoom = 0.0625; self.zoom_to = [0, 0], self.offset = Vector[0, 0]
      self.window = window

      self.canvas = Canvas.new(game_map: self, window: self.window)
      self.detail_window = DetailWindow.new(game_map: self, window: self.window)

      self.a_star_map = Array.new

      self.visible_pois = (pois << init_map).flatten!.select { |poi| poi.draw? }
      (terrain << init_terrain).flatten!
      generate_cities
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
        self.visible_pois = pois
      when 1
        self.zoom = 0.25
        self.zoom_to = zoom_from
        self.offset = Vector.elements(zoom_to.map{|z| ([4, 44, z].sort[1]-4) * 67 }) * 4
        self.visible_pois = pois.select { |poi| poi.draw? }
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
      self.visible_pois = pois.select { |poi| poi.draw? }
      return true
    end

    def meter_per_pixel
      62.5 / zoom
    end

    private
    # Generates Cities based on region population. TODO: implement regions, complete stub
    def generate_cities
      cities = pois.select{|p| Town === p}
      cities.sort { |a, b| a.population <=> b.population }
    end

    # Some Terrain Presets
    def init_terrain
      [
        Terrain.new(
          type: :mountains,
          game_map: self,
          vertices: [
            Vector[2000,2000], Vector[2150,2000], Vector[3000, 2200], Vector[3200,3500],
            Vector[2800,3000], Vector[2300,3200], Vector[2100, 2200]
          ]
        ),
        Terrain.new(
          type: :sea,
          game_map: self,
          vertices: [
            Vector[5000,5000], Vector[5150,5000], Vector[6000, 5200], Vector[6200,6500],
            Vector[5800,6000], Vector[5300,6200], Vector[5100, 5200]
          ]
        )
      ]
    end

    # Some City presets
    def init_map
      [
        Town.new(
          location: Vector[6400, 6400], 
          game_map: self,
          capital: true,
          name: "Baldurs Gate", 
          population: 150000,
          alignments: [:lawful_good, :good]
        ), Town.new(
          location: Vector[2800, 2600],
          game_map: self,
          name: "Random Metropolis",
          population: 25000
        ), Town.new(
          location: Vector[9600, 1600],
          game_map: self,
          name: "Random City",
          population: 15000
        ), Town.new(
          location: Vector[4800, 6400],
          game_map: self,
          name: "Random Town",
          population: 3500
        )
      ] + [ 20.times.map do |i|
          Town.new(
            location: Vector[rand(100..12000), rand(100..12000)],
            game_map: self,
            name: "RND ##{i}",
            population: rand(100..10000)
          )
        end ]
    end
  end
end
