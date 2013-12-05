require 'gosu'
require 'rmagick'
$: << ''
# Include working directory
Dir["*.rb"].each do |file|
  require file unless file == "../world_gen.rb"
end

module WorldGen
  class MyWindow < Gosu::Window
    attr_accessor :zoom_pause
    def initialize
      self.zoom_pause = @last_frame = 0.0
      @window = self

      @gm = GameMap.new self
      @detail_window = @gm.new_detail_window

      super((@gm.window_size * 1.5).to_i, @gm.window_size, false)

      @bg = Gosu::Image.new(
        self, Magick::Image.new((@gm.window_size * 1.5).to_i, @gm.window_size), false
      )

      redraw_map
      @details = Gosu::Image.new(self, @detail_window.image, false)
      @map = Gosu::Image.new(self, @canvas.image, false)
    end

    def update
      self.zoom_pause -= delta
    end


    def draw
      @bg.draw 0, 0, 0
      @map.draw @gm.canvas.padding, @gm.canvas.padding, 0
      @details.draw @gm.canvas.size + @gm.canvas.padding * 2, @gm.canvas.padding, 0
    end

    def button_up id
      if zoom_pause <= 0 and inside_map?
        case id
        when Gosu::MsWheelUp
          if @gm.zoom_in([mouse_x - @gm.canvas.padding, mouse_y - @gm.canvas.padding])
            self.zoom_pause = 0.5
            redraw_map
          end
        when Gosu::MsWheelDown
          if @gm.zoom_out
            self.zoom_pause = 0.5
            redraw_map
          end
        when Gosu::MsLeft
        end
      end
    end

    def needs_cursor?
      true
    end

    private
    def redraw_map
      @canvas = @gm.new_canvas

      @canvas.draw_terrains
      @canvas.draw_pois

      @canvas.draw_grid
      @canvas.draw_distance_marker
      @map = Gosu::Image.new(self, @canvas.image, false)
    end

    def inside_map?
      [mouse_x, mouse_y].each{|m| @gm.canvas.boundaries.include? m}.size == 2
    end

    def redraw_details
      @details = @gm.new_detail_window
    end

    def delta
      @this_frame = Gosu::milliseconds
      @delta = (@this_frame - @last_frame) / 1000.0
      @last_frame = @this_frame
      @delta
    end
  end
end


window = WorldGen::MyWindow.new
window.show
