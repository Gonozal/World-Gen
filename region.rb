module WorldGen
  class Region
    attr_accessor :game_map
    attr_accessor :name, :age, :population
    attr_accessor :pois, :sorted_pois, :visible_pois, :terrain, :roads, :rivers
    attr_accessor :towns_tbg

    def initialize(params = {})
      params.each do |key, val|
        send "#{key}=".to_sym, val
      end
    end

    def initialize_imports
      self.pois = init_map
      self.roads = init_roads
      self.rivers = init_rivers
      self.terrain = init_terrain
      sort_pois
    end

    def visible_pois
      pois.select { |poi| poi.draw? }
    end

    def after_initialize
      # Offset terrain and calculate movement costs from image
      offset_terrain
      game_map.window.action_queue << {redraw: :map}
      game_map.window.action_queue << {draw: [:terrains, :cost]}
      game_map.window.action_queue << {draw: [:rivers, :cost]}
      game_map.window.action_queue << {terrain_costs: nil}
      update_roads
      game_map.window.action_queue << {redraw: :land_value}
      game_map.window.action_queue << {redraw: :town_distance}
      game_map.window.action_queue << {redraw: :city_distance}
      game_map.window.action_queue << {land_values: nil}

      game_map.window.action_queue << { generate_towns: [self, :city] }
      # self.visible_pois = pois.select { |poi| poi.draw? }
    end

    def largest_town
      if sorted_pois.first.population > population ** 0.5 * 15
        :existing
      else
        :new
      end
    end

    def theoretical_town_sizes
      if largest_town == :existing
        last_size = sorted_pois.first.population
      else
        last_size = (population ** 0.5 * 15).round
      end
      towns = []
      towns << [Town.population_to_type(last_size), last_size]
      i = 0
      begin
        modifier = (i < 1)? 0.4 : 0.85
        last_size = (last_size * modifier).round
        type = Town.population_to_type(last_size)
        towns << [type, last_size]
        i += 1
      end while [:metropolis, :city].include? type

      (i*9).times do |n|
        last_size = 7000 - 7000/(i*9) * n + rand(0..1000)
        towns << [:town, last_size]
      end
      towns
    end

    def needed_towns
      pois_copy = sorted_pois.map{|poi| [poi.type, poi.population]}
      towns_tbg = theoretical_town_sizes
      towns_tbg.map do |type, population|
        if pois_copy.empty?
          [type, population]
        else
          (pois_copy.shift[1] * 1.1 >= population)? nil : [type, population]
        end
      end.compact
    end

    private
    def offset_terrain
      terrain.each do |t|
        # t.add_offsets
        game_map.window.action_queue << {offset: t}
      end
    end

    def update_roads
      roads.each do |r|
        game_map.window.action_queue << {path: r}
        # r.find_path
      end
    end

    def update_pois
      pois.each do |poi|
        if Town === poi
          poi.instance_eval { calculate_shops; prep_shop_hashes; add_influences }
          self.population -= poi.population
        end
      end
    end

    def sort_pois
      cities = pois.select{|p| Town === p}
      self.sorted_pois = cities.sort {|a, b| a.population <=> b.population}
    end

    def init_terrain
      [
        Terrain.new(
          type: :mountain,
          game_map: game_map,
          mult: 26,
          vertices: [
            Vector[98, 238], Vector[126, 239], Vector[124, 260], Vector[131, 267],
            Vector[123, 276], Vector[110, 280], Vector[90, 278], Vector[81, 272],
            Vector[95, 253]
          ]
        ),
        Terrain.new(
          type: :mountain,
          game_map: game_map,
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
          game_map: game_map,
          mult: 26,
          vertices: [
            Vector[54, 254], Vector[70, 253], Vector[72, 264], Vector[65, 271],
            Vector[58, 271], Vector[59, 265], Vector[52, 262]
          ]
        ),
        Terrain.new(
          type: :sea,
          game_map: game_map,
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
          game_map: game_map,
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
          game_map: game_map,
          vertices: [
            Vector[209, 258], Vector[264, 257], Vector[290, 276], Vector[315, 277],
            Vector[325, 286], Vector[319, 297], Vector[292, 299], Vector[284, 304],
            Vector[265, 303], Vector[261, 295], Vector[235, 297], Vector[226, 291],
            Vector[227, 279], Vector[208, 274]
          ]
        ),
        Terrain.new(
          type: :forest,
          game_map: game_map,
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
          game_map: game_map,
          vertices: [
            Vector[42, 299], Vector[55, 286], Vector[83, 286], Vector[88, 301],
            Vector[102, 313], Vector[107, 335], Vector[92, 336], Vector[87, 327],
            Vector[42, 314]
          ]
        ),
        Terrain.new(
          type: :lake,
          mult: 26,
          game_map: game_map,
          vertices: [
            Vector[0, 332], Vector[10, 333], Vector[35, 309], Vector[35, 323],
            Vector[73, 326], Vector[74, 332], Vector[53, 339], Vector[44, 396],
            Vector[40, 396], Vector[33, 353], Vector[0, 374]
          ]
        ),
        Terrain.new(
          type: :swamp,
          game_map: game_map,
          mult: 26,
          vertices: [
            Vector[126, 380], Vector[151, 384], Vector[158, 412], Vector[146, 423],
            Vector[115, 415], Vector[110, 405]
          ]
        )
      ]
    end

    def init_rivers
      [
        River.new(
          path: "M431.286,195.59c-23.475-7.13-40.084-22.192-49.717-22.599c-9.633-0.407-13.557,9.908-21.471,14.689c-7.912,4.778-28.842,1.614-43.502,2.26c-14.66,0.645-38.809-4.109-53.672-10.17",
          scale: 1.61,
          game_map: game_map
        ),
        River.new(
          path: "M262.925,179.771c-14.864-6.062-11.364-51.982-25.989-62.146c-14.625-10.164-25.177-4.116-32.901-19.015",
          scale: 1.61,
          game_map: game_map
        ),
        River.new(
          path: "M204.035,98.609c-7.724-14.899-30.141-3.932-33.766-12.624s-7.358-31.317-36.158-24.859s-27.24-16.047-47.458-10.169",
          scale: 1.61,
          game_map: game_map
        ),
        River.new(
          path: "M194.167,219.5c0,0,5.666-6.667,15.333-10.667s22,4,33.667,0s24.992-19.629,25.435-26.961",
          scale: 1.61,
          game_map: game_map
        ),
        River.new(
          path: "M372.875,359.375c0,0-8.25-3.961-10.375-5.543s-8.333-18-11-22s-14.667-10.666-32.667-12.333s-70,2.333-84.667-5.667s-45.333-58.333-45.333-58.333",
          scale: 1.61,
          game_map: game_map
        )
      ]
    end

    # Some City presets
    def init_map
      [
        Town.new(
          location: Vector[211, 243],
          mult: 26,
          region: self,
          capital: true,
          name: "Highmoon",
          population: 8000,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[375, 275],
          mult: 26,
          region: self,
          name: "Ordulin",
          population: 36330,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[228, 320],
          mult: 26,
          region: self,
          name: "Archenbridge",
          population: 8000,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[184, 433],
          mult: 26,
          region: self,
          name: "Daerlun",
          population: 52477,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[220, 455],
          mult: 26,
          region: self,
          name: "Urmlaspyr",
          population: 18000,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[300, 382],
          mult: 26,
          region: self,
          name: "Saerloon",
          population: 54496,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[353, 357],
          mult: 26,
          region: self,
          name: "Selgaunt",
          population: 56514,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[438, 254],
          mult: 26,
          region: self,
          name: "Yhaunn",
          population: 25000,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[13, 305],
          mult: 26,
          region: self,
          name: "Arabel",
          population: 30600,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[25, 225],
          mult: 26,
          region: self,
          name: "Tilverton Scar",
          population: 50,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[216, 130],
          mult: 26,
          region: self,
          name: "Ashabenford",
          population: 455,
          alignments: [:lawful_good, :good]
        ),
        Town.new(
          location: Vector[471, 196],
          mult: 26,
          region: self,
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
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[375, 275],
          end: Vector[211, 243],
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[375, 275],
          end: Vector[438, 254],
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[375, 275],
          end: Vector[228, 320],
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[353, 357],
          end: Vector[300, 382],
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[300, 382],
          end: Vector[220, 455],
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[300, 382],
          end: Vector[184, 433],
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[184, 433],
          end: Vector[228, 320],
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[13, 305],
          end: Vector[211, 243],
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[216, 130],
          end: Vector[25, 225],
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[220, 455],
          end: Vector[184, 433],
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[353, 357],
          end: Vector[438, 254],
          game_map: game_map
        }),
        Road.new({
          mult: 26,
          start: Vector[375, 275],
          end: Vector[353, 357],
          game_map: game_map
        })
      ]
    end
  end
end
