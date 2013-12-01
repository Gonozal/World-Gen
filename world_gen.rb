require 'matrix'
require 'gosu'
require 'RMagick'
$: << ''
# Include working directory
Dir["*.rb"].each do |file|
  require file unless file == "../world_gen.rb"
end

class MyWindow < Gosu::Window
  def initialize
    gm = GameMap.new self
    @canvas = gm.canvas
    super(gm.window_size, gm.window_size, false)

    @bg = Gosu::Image.new(self, Magick::Image.new(gm.window_size, gm.window_size), false)

    gm.pois.each do |poi|
      @canvas.draw_poi poi
    end
    @canvas.draw_grid


    @map = Gosu::Image.new(self, @canvas.image, false)
  end

  def update
  end

  def needs_cursor?
    true
  end

  def draw
    @bg.draw 0, 0, 0
    @map.draw 10, 10, 0
  end
end

window = MyWindow.new
window.show
