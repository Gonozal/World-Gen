class PointOfInterest
  # name: String: name of the POI
  # location: Vector[Integer, Integer]: with 2 coordinates (x and y)
  # :influences: Array[Influence]: with 0-n influence instances
  # radius: Float: diameter of the POI in km
  # radius: Float: diameter of the POI in km as displayed on the map
  # area: Float: area of the POI in ha (hectare, 10,000 square meters)
  attr_accessor :name, :location, :influences, :radius, :area, :map_radius
  def initialize(params = {})
    raise ArgumentError, "location" unless valid_params? params

    params.each do |key, val|
      send "#{key}=".to_sym, val
    end

    self.influences = []
  end

  def display_name
    if Town === self
      name_suffix = " (#{type.to_s.upcase[0]}#{(capital)? "-C": ""})"
    end
    "'#{name}#{name_suffix}'"
  end

  def influence_magnitude(position)
    influences.map do |influence|
      influence.magnitude(position)
    end.inject(0, :+)
  end

  def symbol
    if Town === self
      if capital
        :star
      else
        case self.type
        when :metropolis then :rectangle
        when :city then :hollow_rectangle
        when :town then :circle
        when :village then :hollow_circle
        end
      end
    end
  end

  def map_radius
    [radius * 5, 2].max
  end

  private
  def valid_params? params
    params.has_key? :location and params[:location].present?
  end
end
