class PointOfInterest
  # name: String: name of the POI
  # location: Vector[Integer, Integer]: with 2 coordinates (x and y)
  # :influences: Array[Influence]: with 0-n influence instances
  # size: Float: diameter of the POI in km
  # area: Float: area of the POI in ha (hectare, 10,000 square meters)
  attr_accessor :name, :location, :influences, :size, :area
  def initialize(params = {})
    raise ArgumentError, "location and size required" unless valid_params? params

    params.each do |key, val|
      send "#{key}=".to_sym, val
    end

    self.influences = []
  end

  def draw_icon(params = {})
    steps = params[:points] * 2
    coordinates = []
    steps.times do |i|
      distance = (i % 2 == 0)? (0.5 * params[:size]) : params[:size]
      coordinates << (location[0] + distance * Math.sin(Math::PI * 2 / steps * i)).to_i
      coordinates << (location[1] + distance * Math.cos(Math::PI * 2 / steps * i)).to_i
    end
    params[:img].polyline coordinates, color: :black, closed: true
  end

  def influence_magnitude(position)
    influences.map do |influence|
      influence.magnitude(position)
    end.inject(0, :+)
  end

  private
  def valid_params? params
    params.has_key? :location and params[:location].present? and
      params.has_key? :size and params[:size].present?
  end
end
