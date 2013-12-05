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
      # calculate_shops
      # prep_shop_hashes
      # add_influences
      calculate_supporting_radius
      self.magic_propability ||= 50
      self.capital ||= false
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
      self.supporting_radius = (population / (180 * Math::PI)) ** 0.5 / game_map.zoom
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

    def add_influences
      influence = Influence.new(parent: self, multiplier: population ** 0.5)
      self.influences << influence
    end
    # Assigns fractions of all clergyman to a religion and calculates cleric and priest count
  end
end
