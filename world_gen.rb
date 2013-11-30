require 'matrix'
require 'gosu'
require 'texplay'

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
    self.caption = 'Hello World!'

    @bg = TexPlay.create_image(self, gm.window_size, gm.window_size)
    @bg.fill 1, 1, color: :white

    @img = TexPlay.create_image(self, gm.size+1, gm.size+1)
    @img.fill 1, 1, color: :white

    gm.pois.each do |poi|
      poi.draw_icon @img
    end


    # gm.pois.each do |poi|
    #   size = 8
    #   offset = size / 2
    #   offset
    #   # Draw symbol for POIs
    # end

    11.times do |i|
      pos = gm.size / 10 * i
      @img.line 0, pos, gm.size, pos, thickness: 1, color: :black
      @img.line pos, 0, pos, gm.size, thickness: 1, color: :black
    end
  end

  def update
  end

  def draw
    @bg.draw 0, 0, 0
    @img.draw 10, 10, 1
  end
end

window = MyWindow.new
window.show
