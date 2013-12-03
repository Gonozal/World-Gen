module WorldGen
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
    guardsman: 150,
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
end
