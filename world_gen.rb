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
    attr_accessor :init_step
    attr_accessor :draw_pathfinding

    def initialize
      self.zoom_pause = @last_frame = 0.0
      self.init_step = 0

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
      gradually_initialize
    end

    def gradually_initialize
      return nil if init_step > 5
      case init_step
      when 0
        @gm.update_pois
      when 1
        @gm.offset_terrain
        redraw_map
      when 2
        @gm.set_terrain_costs
      when 3
        @gm.update_roads
        redraw_map
      when 4
        @gm.set_terrain_costs
      end
      self.init_step += 1
    end


    def draw
      @bg.draw 0, 0, 0
      @map.draw @gm.canvas.padding, @gm.canvas.padding, 0
      @details.draw @gm.canvas.size + @gm.canvas.padding * 2, @gm.canvas.padding, 0
      @cost_map.draw @gm.canvas.padding, @gm.canvas.padding, 0 if draw_pathfinding
    end

    def button_up id
      case id
      when Gosu::KbP
        self.draw_pathfinding = !draw_pathfinding
      end
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
      @canvas.draw_terrains :cost
      @canvas.draw_pois

      @canvas.draw_roads
      @canvas.draw_roads :cost
      @canvas.draw_grid
      @canvas.draw_distance_marker

      # @gm.canvas.draw_costs
      @details = Gosu::Image.new(self, @detail_window.image, false)
      @map = Gosu::Image.new(self, @canvas.image, false)
      @canvas.cost_image.resize!(@canvas.size + 1, @canvas.size + 1)
      @cost_map = Gosu::Image.new(self, @canvas.cost_image, false)
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
