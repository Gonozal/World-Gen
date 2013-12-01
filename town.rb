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
  attr_accessor :shops, :magic_shops, :exceptional_shops

  # City types and what range of possible population densities they have
  DENSITY = {
    metropolis: 10000..25000,
    city: 6000..10000,
    town: 4000..6000,
    village: 1000..4000
  }
  # City types and how many people those corrospond to
  POPULATION = {
    village: 20..1000,
    town: 1000..8000,
    city: 8000..20000,
    metropolis: 20000..200000
  }
  # How many inhabitants are needed for each business/profession
  SUPPORT_VALUES = {
    shoemaker: 250,
    leatherworker: 250,
    tailor: 250,
    jeweler: 400,
    tavern: 400,
    mason: 500,
    carpenter: 550,
    cooper: 700,            # Fassbinder
    baker: 800,
    wine_seller: 900,
    hatmaker: 950,
    woodseller: 2400,
    magic_shop: 2800,
    butcher: 1200,
    spice_merchant: 1400,
    blacksmith: 1500,
    painter: 1500,
    locksmith: 1900,
    inn: 2000,
    sculptor: 2000,
    glovemaker: 2400,
    woodcarver: 2400,
    nobles: 200,
    advocate: 650,
    clergyman: 80
  }
  # What shops have the potential to carry magic items?
  MAGIC_ITEM_TRADER = [:shoemaker, :leatherworker, :tailor, :jeweler, :hatmaker,
                        :magic_shop, :blacksmith, :glovemaker, :woodcarver]

  # Default values for the religion fraction
  # TODO: refactor out into some global initialisation method
  DEITIES = {
    lawful_good: {
      amaunator:  1000,  # [Lawful Good] [Greater] Keeper of the Yellow Sun
      chauntea:   1000,  # [Lawful Good] [Greater] The Great Mother
      moradin:    1000,  # [Lawful Good] [Greater] The Soul Forger
      torm:       1000   # [Lawful Good] [Greater] The Loyal Fury
    }, good: {
      corellon:   1000,  # [Good]        [Greater] First of the Seldarine
      selune:     1000,  # [Good]        [Greater] The Moonmaiden
      sune:       1000   # [Good]        [Greater] The Lady of Love
    }, unaligned: {
      kelemvor:   1000,  # [Unaligned]   [Greater] Lord of the Dead
      oghma:      1000,  # [Unaligned]   [Greater] The Binder of What is Known
      silvanus:   1000,  # [Unaligned]   [Greater] The Forest Father
      tempus:     1000   # [Unaligned]   [Greater] The Foehammer
    }, evil: {
      asmodeus:   1000,  # [Evil]        [Greater] Supreme Master of the Nine Hells
      bane:       1000,  # [Evil]        [Greater] The Black Lord
      shar:       1000   # [Evil]        [Greater] Mistress of the Night
    }, chaotic_evil: {
      cyric:      1000,  # [Chaotic Evil][Greater] Prince of Lies
      ghaunadaur: 1000,  # [Chaotic Evil][Greater] That Which Lurks
      gruumsh:    1000,  # [Chaotic Evil][Greater] The One-Eyed God
      lolth:      1000   # [Chaotic Evil][Greater] Queen of the Demonweb Pits
    }
  }
  # How does the presence of races shift religion fraction?
  RACE_WORSHIP_INFLUENCE = {
    eladrin: {
      good: {
        corellon: 1000,
        sune: 500
      },
    }, elves: {
      good: {
        corellon: 750
      }
    }, half_elves: {
      good: {
        corellon: 500,
        sune: 750
      }
    }, humans: {
      good: {
        sune: 500
      }
    }, orcs: {
      chaotic_evil: {
        gruumsh: 1000
      }
    }, half_orcs: {
      chaotic_evil: {
        gruumsh: 500
      }
    }, dwarves: {
      lawful_good: {
        moradin: 1000
      }
    }
  }

  # Sets up empty arrays/hashes for attributes that need it
  def initialize(params = {})
    self.npcs = self.alignments = []
    self.race_fraction = self.religion_fraction = {}
    self.shops = self.magic_shops = self.exceptional_shops = {}

    params.each do |key, val|
      send "#{key}=".to_sym, val
    end

    population_to_type
    population_to_radius
    calculate_shops
    prep_shop_hashes
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
    # Set radius of the town
    self.radius = (population / (self.density * 3.142)) ** 0.5
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
          exceptional_shops[key] += 1
          magic_shops[key] += 1
        elsif rand(1000) < magic_propability and MAGIC_ITEM_TRADER.include? key
          shops[key] -= 1
          magic_shops[key] += 1
        end
      end
    end
    # Clean up magic and exceptional shops
    magic_shops.select{ |key, val| val > 0 }
    exceptional_shops.select{ |key, val| val > 0 }
  end

  # Assigns fractions of all clergyman to a religion and calculates cleric and priest count
end
