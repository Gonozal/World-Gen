module WorldGen
  class Town < PointOfInterest
    # population: Integer: population of the town
    # type: Symbol: (lowercase) type like town, village, city, ...
    # npcs: Array[Npc]: list of NPC instances
    # race_fraction: Hash[Symbol => Float]: How each race is represented in this town
    # religion_fraction: Hash[Symbol => Float]: How each religion is representes in this town
    # capital: Boolean: Is this town the/a capital of the region?
    attr_accessor :population, :type, :npcs, :race_fraction, :religion_fraction, :capital
    # alignments: Array[Symbol]: What Alignemts does this town have?
    # magic_propability: Integer: Permille chance a shop will cary magic items
    # exceptional_propability: Integer: Permille chance a shop will cary exceptional items
    # density: Integer: Inhabitants per square kilometer
    attr_accessor :alignments, :magic_propability, :exceptional_propability, :density
    # shops: Hash[Symbol => Integer]: How many of each profession there are in this town
    # magic_shops: Hash[Symbol => Integer]: How many magic stores of each type there are
    # exceptional_shops: Hash[Symbol => Integer]: Same as above but even rarer
    attr_accessor :shops, :magic_shops, :exceptional_shops, :supporting_radius

    # Sets up empty arrays/hashes for attributes that need it
    def initialize(params = {})
      self.npcs = self.alignments = []
      self.race_fraction = self.religion_fraction = {}
      self.shops = self.magic_shops = self.exceptional_shops = {}

      params[:location] *= params.fetch(:mult, 16)
      params.delete(:mult)

      super

      population_to_type
      population_to_radius
      calculate_supporting_radius
      self.magic_propability ||= 50
      self.capital ||= false
    end

    def land_value_offset
      max_pop = region.game_map.sorted_pois.first.population
      population.to_f / max_pop * 200
    end

    def land_values
      if type == :city or type == :metropolis
        @land_values ||= positive_land_values + negative_land_values
      else
        @land_values ||= negative_land_values
      end
    end

    def city_influences
      [
        [6, "rgba(255,255,255,1)"],
        [4, "rgba(0,0,0,1)"]
      ]
    end

    def positive_land_values
      rgb = land_value_offset + rand(26)
      positive_color = "rgba(#{rgb}, #{rgb}, #{rgb}, 0.15)"
      @positive_land_values = [
        [2.25, positive_color],
      ]
      if type == :metropolis
        @positive_land_values + [
          [3.25, positive_color]
        ]
      end
      @positive_land_values
    end

    def negative_land_values
      @negative_land_values = [
        [1.5, "rgba(0,0,0,0.4)"],
        [6, "rgba(0,0,0,0.1)"]
      ]
    end

    def self.population_to_type(population)
      POPULATION.each do |key, val|
        return key if val.include? population
      end
    end

    def self.generate(land_values, region, type)
      @towns_tbg ||= region.needed_towns
      new_towns = []
      used_locations = []
      land_values.each do |land_type, x, y|
        if @towns_tbg.empty?
          region.visible_pois = region.pois.select { |poi| poi.draw? }
          region.game_map.window.action_queue << { redraw: :map }
          return []
        end
        location = Vector[x, y]
        next_town = @towns_tbg.first
        next unless legal_new_town_position(used_locations, location, next_town[1])
        if land_type == :town
          next unless next_town[0] == :town or next_town[0] == :village
        elsif land_type == :city
          next unless next_town[0] == :city or next_town[0] == :metropolis
        end
        population = @towns_tbg.shift[1]
        town = Town.new({
          location: location,
          mult: 16,
          region: region,
          name: "#{x}:#{y}",
          population: population,
          alignments: [:lawful_good, :good]
        })
        new_towns << town
        region.pois << town
        used_locations << location

        # add roads
        if land_type == :city
          town.add_road
        end
      end
      if land_values.empty?
        region.visible_pois = region.pois.select { |poi| poi.draw? }
        region.game_map.window.action_queue << { redraw: :map }
        return []
      else
        region.game_map.window.action_queue << { redraw: :land_value }
        region.game_map.window.action_queue << { land_values: nil }
        region.game_map.window.action_queue << { generate_towns: [region, type] }
        return new_towns
      end
    end

    def self.legal_new_town_position(used_locations, location, population)
      used_locations.each do |used_location|
        return false if (used_location - location).magnitude < 60 + population ** 0.5
      end
      true
    end

    def add_road
      region.game_map.canvas.redraw :cost
      region.game_map.set_terrain_costs
      distance = region.roads.inject([9999, 9999]) do |min, road|
        [min, road.distance(location)].sort{|a, b| a[0] <=> b[0]}[0]
      end
      road = Road.new({
        mult: 16,
        start: (location / 16).round,
        end: (distance[1] / 16).round,
        game_map: region.game_map
      })

      road.find_path
      region.roads << road
      distance
    end

    private
    # Calculates town type and a rough radius based on population
    def population_to_type
      POPULATION.each do |key, val|
        self.type = key
        break if val.include? population
      end
    end

    # Calculates town radius and area from population amount
    def population_to_radius
      # First, decide where in the town-type population-range we are at
      range = POPULATION[type]
      percentile = (population - range.first).to_f / (range.last - range.first)

      # Get to the same percentile of the town density
      self.density = DENSITY[type].first +
        (DENSITY[type].last - DENSITY[type].first).to_f * percentile
      # Set radius of the town in meters
      self.radius = (population / (self.density * Math::PI)) ** 0.5 * 1000
    end

    # Goes through the list of possible shops and assigns them according to population
    def calculate_shops
      self.shops = SUPPORT_VALUES.inject({}) do |h, (key, val)|
        if population / val >= 1
          amount = population / val
        else
          amount = (((population / val) ** 2 * 100).to_i > rand(100))? 1 : 0
        end
        h[key] = amount; h
      end
    end

    def calculate_supporting_radius
      self.supporting_radius = (population / (180 * Math::PI)) ** 0.5 / region.game_map.zoom
    end

    # Make zero-value copies of the shops hash for magic and exceptional shops
    def prep_shop_hashes
      shops.each do |key, val|
        self.magic_shops[key] = 0
        self.exceptional_shops[key] = 0
      end
    end

    # Goes through (some) shops and rolls to see if they carry magic or even rarer items
    def calculate_magic_shops
      # Determine exceptional and magic item shop amount
      shops.each do |key, val|
        val.times do |i|
          rnd = rand(1000)      # Roll propability for each individual shop
          if rnd < exceptional_propability
            self.shops[key] -= 1
            self.exceptional_shops[key] += 1
            self.magic_shops[key] += 1
          elsif rand(1000) < magic_propability and MAGIC_ITEM_TRADER.include? key
            self.shops[key] -= 1
            self.magic_shops[key] += 1
          end
        end
      end
      # Clean up magic and exceptional shops
      magic_shops.select{ |key, val| val > 0 }
      exceptional_shops.select{ |key, val| val > 0 }
    end
  end
end
