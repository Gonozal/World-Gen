class Town < PointOfInterest
  # population: Integer: population of the town
  # type: Symbol: (lowercase) type like town, village, city, ...
  # npcs: Array[Npc]: list of NPC instances
  # race_fraction: Hash[Symbol => Float]: How each race is represented in this town
  # religion_fraction: Hash[Symbol => Float]: How each religion is representes in this town
  attr_accessor :population, :type, :npcs, :race_fraction, :religion_fraction
  # alignments: Array[Integer]: What Alignemts does this town have?
  # businesses: Hash[Symbol => Integer]: How many of each profession there are in this town
  # magic_businesses: Hash[Symbol => Integer]: How many magic stores of each type there are
  # exceptional_businesses: Hash[Symbol => Integer]: Same as above but even rarer
  attr_accessor :businesses, :magic_businesses, :exceptional_businesses

  # City types and what range of possible population densities they have
  DENSITY = {
    metropolis: 25000..35000,
    city: 15000..25000,
    town: 8000..15000,
    village: 4000..8000
  }
  # City types and how many people those corrospond to
  POPULATION = {
    village: 20..1000,
    town: 1000..8000,
    city: 8000..12000,
    metropolis: 12000..150000
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
  # What businesses have the potential to carry magic items?
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
    self.npcs = []
    self.race_fraction = self.religion_fraction = {}
    self.businesses = self.magic_businesses = self.exceptional_businesses = {}
    super(params)
  end

  private
  # Calculates town type and a rough size based on population
  def population_to_type
    POPULATION.each do |key, val|
      self.type = key
      break if val.include? population
    end
  end

  # Calculates town size and area from population amount
  def population_to_size
    # First, decide where in the town-type population-range we are at
    percentile = POPULATION[type].instance_eval do
      (last - population).to_f / (last - first)
    end
    # Get to the same percentile of the town density
    density = DENSITY.instance_eval { (last - first).to_f * percentile }
    # Set size (meaning diameter) of the town
    self.size = (population / (density * 3.142)) ** 0.5 * 2
  end

  # Goes through the list of possible businesses and assigns them according to population
  def calculate_businesses
    self.businesses = Hash[SUPPORT_VALUES.map do |key, val|
      if population / val >= 1
        amount = val
      else
        amount = (((population / val) ** 2 * 100).to_i > rand(100))? 1 : 0
      end
      [key, amount]
    end]
  end

  # Goes through (some) businesses and rolls to see if they carry magic or even rarer items
  def calculate_magic_businesses
  end

  # Assigns fractions of all clergyman to a religion and calculates cleric and priest count
end
