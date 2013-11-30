class Influence
  attr_accessor :type, :multiplier, :parent

  def initialize(params = {})
    raise ArgumentError, "parent and multiplier required" unless valid_params? params
    params.each do |key, val|
      send "#{key}=".to_sym, val
    end
    adjust_mult_from_size
  end

  # Magnitude and Gradient of only this infleunce field at a given position
  def magnitude position
    return multiplier if distance(position) < parent.size / 2
    multiplier / distance(position) ** 2
  end

  def gradient position
    return Vector[0, 0] if distance(position) < parent.size / 2
    -2 * multiplier / distance(position) ** 3 * direction(position)
  end

  # Reach, in case you need a radius to draw a circle of the influence
  def reach
    (multiplier ** 0.5 * 2.55).to_i + 1
  end


  # Vector math to get Distance and Direction
  def distance position
    (parent.location - position).magnitude / 10
  end

  def direction position
    (parent.location - position).normalize
  end

  private
  def valid_params? params
    params.has_key? :parent and params[:parent].present? and
      params.has_key? :multiplier and params[:multiplier].present?
  end

  # Adjusts the multiplier, so that it applies to the outer bounds of the object
  # example: A POI has a size of 4 and originally a magnitude of 2
  # this function increases the magnitude so it becomes 2 at the edge of the POI
  def adjust_mult_from_size
    self.multiplier = multiplier.to_f * [(parent.size.to_f / 2), 1.0].max ** 2
  end
end
