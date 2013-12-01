require 'matrix'
require 'gosu'
require 'RMagick'
$: << ''
# Include working directory
Dir["*.rb"].each do |file|
  puts file
  require file unless file == "../world_gen.rb"
end

class MyWindow < Gosu::Window
  def initialize
    gm = GameMap.new
    super(gm.window_size, gm.window_size, false)

    @bg = Gosu::Image.new(self, Magick::Image.new(gm.window_size, gm.window_size), false)
    canvas = Magick::Image.new(gm.size, gm.size)
    draw = GameMap.default_drawer

    gm.pois.each do |poi|
      poi.draw_symbol(points: 5, size: 20, img: canvas, draw: draw)
    end

    @canvas = Gosu::Image.new(self, canvas, false)
  end

  def update
  end

  def draw
    @bg.draw 0, 0, 0
    @canvas.draw 10, 10, 1
  end
end

window = MyWindow.new
window.show
