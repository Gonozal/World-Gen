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
    attr_accessor :maps
    attr_accessor :action_queue

    def initialize
      self.zoom_pause, @last_frame = 0.0, 0.0
      self.draw_mode = [:map]
      self.maps = {}
      self.action_queue = WorldGen::ActionQueue.new
      @window = self
      @gm = GameMap.new self
      @detail_window = @gm.new_detail_window
      super((@gm.window_size * 1.5).to_i, @gm.window_size, false)
      @bg = Gosu::Image.new(
        self, Magick::Image.new((@gm.window_size * 1.5).to_i, @gm.window_size), false
      )
      @canvas = @gm.new_canvas
    end

    def update
      self.zoom_pause -= delta
      @gm.gradually_initialize

      return true if action_queue.empty?
      t = Time.now
      until Time.now - t > 0.1 or action_queue.empty?
        action = action_queue.pop.first
        case action.first
        when :draw then @canvas.draw(*action.last)
        when :redraw then @canvas.redraw action.last
        when :path
          action.last.find_path
          @canvas.draw action.last, :map
        when :offset then action.last.add_offsets
        when :terrain_costs then @gm.set_terrain_costs
        when :land_values then @gm.set_land_values
        when :generate_towns
          towns = Town.generate(@gm.land_values, *action.last).select{|town| town.draw?}
          @canvas.draw towns, :map
        end
      end
    end

    def draw
      @bg.draw 0, 0, 0

      padding = @gm.canvas.padding
      if @details.present?
        @details.draw @gm.canvas.size + @gm.canvas.padding * 2, @gm.canvas.padding, 0
      end
      @maps[draw_mode.last] = Gosu::Image.new(self, @canvas.images[draw_mode.last], false)
      @maps[draw_mode.last].draw padding, padding, 0
    end

    def button_up id
      case id
      when Gosu::KbP
        toggle_draw_mode :cost
      when Gosu::KbM
        toggle_draw_mode :map
      when Gosu::KbL
        toggle_draw_mode :land_value
      when Gosu::KbO
        toggle_draw_mode :town_distance
      when Gosu::KbI
        toggle_draw_mode :city_distance
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

    def redraw_map
      action_queue << {redraw: draw_mode.last}
      @details = Gosu::Image.new(self, @detail_window.image, false)
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
