require 'gosu'
require 'rmagick'
require 'ruby-prof'
$: << ''
# Include working directory
Dir["*.rb"].each do |file|
  require file unless file == "../world_gen.rb"
end

module WorldGen
  class MyWindow < Gosu::Window
    attr_accessor :zoom_pause
    attr_accessor :draw_mode

    def initialize
      self.zoom_pause, @last_frame = 0.0, 0.0
      self.draw_mode = [:map]

      @window = self
      @gm = GameMap.new self
      @detail_window = @gm.new_detail_window
      super((@gm.window_size * 1.5).to_i, @gm.window_size, false)
      @bg = Gosu::Image.new(
        self, Magick::Image.new((@gm.window_size * 1.5).to_i, @gm.window_size), false
      )

      redraw_map
    end

    def update
      self.zoom_pause -= delta
      @gm.gradually_initialize
    end

    def draw
      @bg.draw 0, 0, 0
      @details.draw @gm.canvas.size + @gm.canvas.padding * 2, @gm.canvas.padding, 0

      padding = @gm.canvas.padding
      case draw_mode.last
      when :map
        @map.draw padding, padding, 0
      when :cost
        @cost_map.draw padding, padding, 0
      when :land_value
        @land_value_map.draw padding, padding, 0
      end
    end

    def button_up id
      case id
      when Gosu::KbP
        toggle_draw_mode :cost
      when Gosu::KbM
        toggle_draw_mode :map
      when Gosu::KbL
        toggle_draw_mode :land_value
      end
      if zoom_pause <= 0 and inside_map?
        case id
        when Gosu::MsWheelUp
          if @gm.zoom_in([mouse_x - @gm.canvas.padding, mouse_y - @gm.canvas.padding])
            self.zoom_pause = 2
            redraw_map
          end
        when Gosu::MsWheelDown
          if @gm.zoom_out
            self.zoom_pause = 2
            redraw_map
          end
        when Gosu::MsLeft
        end
      end
    end

    def needs_cursor?
      true
    end

    def redraw_map
      t0 = Time.now
      @canvas = @gm.new_canvas

      @canvas.draw_terrains draw_mode.last
      @canvas.draw_roads draw_mode.last

      @canvas.draw_pois draw_mode.last

      @canvas.draw_grid
      @canvas.draw_distance_marker

      # @gm.canvas.draw_costs
      case draw_mode.last
      when :map
        @map = Gosu::Image.new(self, @canvas.image, false)
      when :cost
        @cost_map = Gosu::Image.new(self, @canvas.cost_image, false)
      when :land_value
        @land_value_map = Gosu::Image.new(self, @canvas.land_value_image, false)
      end
      @details = Gosu::Image.new(self, @detail_window.image, false)
      puts "redraw time: #{Time.now - t0}"
    end

    private
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

    def toggle_draw_mode type
      current_mode = draw_mode.pop
      if current_mode == type
        draw_mode.insert(-1, current_mode)
      else
        draw_mode.delete(current_mode)
        draw_mode << current_mode << type
      end
      redraw_map
    end
  end
end


window = WorldGen::MyWindow.new
window.show
