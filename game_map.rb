module WorldGen
  class GameMap
    attr_accessor :regions, :pois, :terrain, :roads
    attr_accessor :field_cutoff, :field_max, :zoom, :zoom_to
    attr_accessor :visible_pois
    attr_accessor :zoom, :zoom_to, :zoom_from
    attr_accessor :window, :offset, :size
    attr_accessor :detail_window, :canvas
    attr_accessor :a_star_map
    attr_accessor :clipper

    def initialize(window)
      self.field_max = 200.0
      self.zoom = 0.0625; self.zoom_to = [0, 0]; self.offset = Vector[0, 0]
      self.window = window

      # self.a_star_map = Array.new(804){Array.new(804, 100)}

      self.canvas = Canvas.new(game_map: self, window: self.window)
      self.detail_window = DetailWindow.new(game_map: self, window: self.window)

      self.pois = init_map.flatten
      self.visible_pois = pois.select { |poi| poi.draw? }
      self.terrain = init_terrain.flatten
      self.roads = init_roads
    end

    def set_terrain_costs
      size = 804
      self.a_star_map = Array.new(size){Array.new(size, 100)}
      t0 = Time.now
      size.times do |x|
        size.times do |y|
          cost = (255 - canvas.cost_image.pixel_color(x, y).red / 257).round
          a_star_map[x][y] = cost
        end
      end
      puts "Total terrain cost time: #{Time.now - t0}"
    end

    def update_pois
      pois.each do |poi|
        if Town === poi
          poi.instance_eval { calculate_shops; prep_shop_hashes; add_influences }
        end
      end
    end

    def offset_terrain
      terrain.each do |t|
        t.add_offsets
      end
    end

    def update_roads
      roads.each do |r|
        r.find_path
        r.interpolate
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
        self.visible_pois = pois.select { |poi| poi.draw? }
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
          type: :mountain,
          game_map: self,
          mult: 26,
          vertices: [
            Vector[98, 238], Vector[126, 239], Vector[124, 260], Vector[131, 267],
            Vector[123, 276], Vector[110, 280], Vector[90, 278], Vector[81, 272],
            Vector[95, 253]
          ]
        ),
        Terrain.new(
          type: :mountain,
          game_map: self,
          mult: 26,
          vertices: [
            Vector[106, 292], Vector[125, 287], Vector[145, 270], Vector[188, 255],
            Vector[190, 275], Vector[172, 290], Vector[161, 313], Vector[156, 350],
            Vector[139, 369], Vector[127, 365], Vector[118, 350], Vector[123, 329],
            Vector[131, 319], Vector[126, 310], Vector[114, 308], Vector[106, 303]
          ]
        ),
        Terrain.new(
          type: :forest,
          game_map: self,
          mult: 26,
          vertices: [
            Vector[54, 254], Vector[70, 253], Vector[72, 264], Vector[65, 271],
            Vector[58, 271], Vector[59, 265], Vector[52, 262]
          ]
        ),
        Terrain.new(
          type: :sea,
          game_map: self,
          mult: 26,
          vertices: [
            Vector[0, 494], Vector[0, 449], Vector[46, 427], Vector[68, 426],
            Vector[65, 440], Vector[102, 447], Vector[114, 432], Vector[136, 437],
            Vector[139, 457], Vector[157, 461], Vector[168, 452], Vector[231, 468],
            Vector[269, 464], Vector[282, 446], Vector[282, 420], Vector[299, 394],
            Vector[314, 390], Vector[316, 422], Vector[303, 435], Vector[311, 451],
            Vector[343, 446], Vector[349, 435], Vector[343, 424], Vector[352, 413],
            Vector[357, 418], Vector[374, 413], Vector[382, 381], Vector[364, 358],
            Vector[375, 350], Vector[402, 353], Vector[425, 367], Vector[436, 359],
            Vector[457, 375], Vector[468, 379], Vector[477, 377], Vector[476, 365],
            Vector[494, 349], Vector[494, 467], Vector[475, 475], Vector[453, 494],
            Vector[172, 494], Vector[137, 475], Vector[94, 481], Vector[83, 480],
            Vector[47, 489], Vector[40, 494]
          ]
        ),
        Terrain.new(
          type: :forest,
          game_map: self,
          mult: 26,
          vertices: [
            Vector[200, 237], Vector[208, 219], Vector[229, 219], Vector[239, 211],
            Vector[265, 203], Vector[272, 205], Vector[293, 201], Vector[305, 207],
            Vector[300, 225], Vector[280, 226], Vector[244, 240]
          ]
        ),
        Terrain.new(
          type: :forest,
          mult: 26,
          game_map: self,
          vertices: [
            Vector[209, 258], Vector[264, 257], Vector[290, 276], Vector[315, 277],
            Vector[325, 286], Vector[319, 297], Vector[292, 299], Vector[284, 304],
            Vector[265, 303], Vector[261, 295], Vector[235, 297], Vector[226, 291],
            Vector[227, 279], Vector[208, 274]
          ]
        ),
        Terrain.new(
          type: :forest,
          game_map: self,
          mult: 26,
          vertices: [
            Vector[130, 200], Vector[175, 174], Vector[212, 141], Vector[231, 143],
            Vector[241, 159], Vector[250, 162], Vector[256, 179], Vector[250, 181],
            Vector[242, 177], Vector[230, 185], Vector[233, 193], Vector[230, 206],
            Vector[211, 207], Vector[192, 215], Vector[170, 236], Vector[163, 241],
            Vector[159, 246], Vector[151, 245], Vector[152, 235], Vector[136, 229]
          ]
        ),
        Terrain.new(
          type: :forest,
          mult: 26,
          game_map: self,
          vertices: [
            Vector[42, 299], Vector[55, 286], Vector[83, 286], Vector[88, 301],
            Vector[102, 313], Vector[107, 335], Vector[92, 336], Vector[87, 327],
            Vector[42, 314]
          ]
        ),
        Terrain.new(
          type: :lake,
          mult: 26,
          game_map: self,
          vertices: [
            Vector[0, 332], Vector[10, 333], Vector[35, 309], Vector[35, 323],
            Vector[73, 326], Vector[74, 332], Vector[53, 339], Vector[44, 396],
            Vector[40, 396], Vector[33, 353], Vector[0, 374]
          ]
        ),
        Terrain.new(
          type: :swamp,
          game_map: self,
          mult: 26,
          vertices: [
            Vector[126, 380], Vector[151, 384], Vector[158, 412], Vector[146, 423],
            Vector[115, 415], Vector[110, 405]
          ]
        )
      ]
    end

    # Some City presets
    def init_map
      [
        Town.new(
          location: Vector[211, 243],
          mult: 26,
          game_map: self,
          capital: true,
          name: "Highmoon",
          population: 8000,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[375, 275],
          mult: 26,
          game_map: self,
          name: "Ordulin",
          population: 36330,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[228, 320],
          mult: 26,
          game_map: self,
          name: "Archenbridge",
          population: 8000,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[184, 433],
          mult: 26,
          game_map: self,
          name: "Daerlun",
          population: 52477,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[220, 455],
          mult: 26,
          game_map: self,
          name: "Urmlaspyr",
          population: 18000,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[300, 382],
          mult: 26,
          game_map: self,
          name: "Saerloon",
          population: 54496,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[353, 357],
          mult: 26,
          game_map: self,
          name: "Selgaunt",
          population: 56514,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[438, 254],
          mult: 26,
          game_map: self,
          name: "Yhaunn",
          population: 25000,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[13, 305],
          mult: 26,
          game_map: self,
          name: "Arabel",
          population: 30600,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[25, 225],
          mult: 26,
          game_map: self,
          name: "Tilverton Scar",
          population: 50,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[216, 130],
          mult: 26,
          game_map: self,
          name: "Ashabenford",
          population: 455,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[471, 196],
          mult: 26,
          game_map: self,
          name: "Chandlerscross",
          population: 5303,
          alignments: [:lawful_good, :good]
        )
      ]
    end

    def init_roads
      [
        Road.new({
          mult: 26,
          start: Vector[13, 305],
          end: Vector[25, 225],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[375, 275],
          end: Vector[211, 243],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[375, 275],
          end: Vector[438, 254],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[375, 275],
          end: Vector[228, 320],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[353, 357],
          end: Vector[300, 382],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[300, 382],
          end: Vector[220, 455],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[300, 382],
          end: Vector[184, 433],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[184, 433],
          end: Vector[228, 320],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[13, 305],
          end: Vector[211, 243],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[216, 130],
          end: Vector[25, 225],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[220, 455],
          end: Vector[184, 433],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[353, 357],
          end: Vector[438, 254],
          game_map: self
        }),
        Road.new({
          mult: 26,
          start: Vector[375, 275],
          end: Vector[353, 357],
          game_map: self
        })
      ]
    end
  end
end
