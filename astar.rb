require 'enumerator'
require 'benchmark'

# I suppose someone would think I should use a heap here.
# I've found that the built-in sort method is much faster
# than any heap implementation in ruby.  As a plus, the logic
# is easier to follow.
class PriorityQueue
  def initialize
    @list = []
    @i_list = []
  end

  def add(priority, item)
    priority = priority
    # Add @list.length so that sort is always using Fixnum comparisons,
    # which should be fast, rather than whatever is comparison on `item'
    len = @list.length
    i2 = @i_list.index do |p|
      p >= priority
    end || len
    # puts "index found: #{i2}, list length: #{@i_list.length} (cost: #{priority})"
    @list.insert(i2, [priority, len, item])
    @i_list.insert(i2, priority)
    self
  end
  def <<(pritem)
    add(*pritem)
  end
  def next
    @i_list.shift
    (@list.shift)[2]
  end
  def empty?
    @list.empty?
  end
end

class Astar
  def benchmark(params)
    Benchmark.bm(10) do |results|
      results.report("sorted array") do
        do_quiz_solution params
      end
    end
  end

  def do_quiz_solution(params = {})
    @game_map = params[:game_map]
    @terrain = params[:terrain]
    @start = params[:start]
    @goal = [params[:goal][0], params[:goal][1]]
    # puts "start: #{@start[0]}, #{@start[1]}"
    if do_find_path
      declutter @path
    else
      return nil
    end
  end

  def declutter(path)
    anchor = path.first
    last_point = WorldGen::Vector[anchor[0], anchor[1]]

    i = 0
    new_path = []
    until i > path.size - 1
      skip_to = do_skips(anchor, path[i])
      if skip_to == true or skip_to == nil
        last_point = path[i]
        i += 1
      else
        anchor = skip_to
        new_path << skip_to
      end
    end
    new_path.insert(0, path.first)
    new_path << path.last
    new_path.compact!
    new_path.map{|e| e * 16 }
  end


  def do_skips(start, goal)
    cost_start = @terrain[start[0]][start[1]]
    v = goal - start

    major = (v[0] > v[1])? 0 : 1
    minor = (1 - major).abs

    v_max = v[major]
    v_min = v[minor]
    s0 = start[major]
    s1 = start[minor]
    m = v_min.to_f / v_max.to_f
    x0 = nil
    x1 = nil

    index = 0
    v_max.times do |i|
      x0 = s0 + i + 1
      x1 = s1 + (m * (i + 1)).round
      index = i
      if cost_start != ((major == 0)? @terrain[x0][x1] : @terrain[x1][x0])
        break
      end
    end
    if (v_max - 1) == index
      true
    elsif x0 == nil or x1 == nil
      nil
    elsif major == 0
      WorldGen::Vector[x0, x1]
    else
      WorldGen::Vector[x1, x0]
    end
  end


  def do_find_path
    been_there = {}
    pqueue = PriorityQueue.new
    pqueue << [1,[@start,[],1]]
    while !pqueue.empty?
      spot3,path_so_far,cost_so_far = pqueue.next
      spot = spot3[0..1]

      next if been_there[spot]
      newpath = [path_so_far, spot]
      if (spot == @goal)
        @path = []
        newpath.flatten.each_slice(2) {|i,j| @path << WorldGen::Vector[i,j]}
        return @path
      end
      been_there[spot] = 1

      spotsfrom(spot).each do |newspot|
        next if been_there[newspot[0..1]]
        tcost = @terrain[newspot[0]][newspot[1]] * newspot[2]
        switching_cost = (@terrain[newspot[0]][newspot[1]] - @terrain[spot[0]][spot[1]])
        newcost = cost_so_far + tcost + switching_cost.abs * 4
        pqueue << [newcost + estimate(newspot), [newspot,newpath,newcost]]
      end
    end
    return nil
  end

  def estimate(spot)
    x = spot[0]
    y = spot[1]
    (((x - @goal[0]) ** 2 + (y - @goal[1]) ** 2) ** 0.5) * 115
  end

  def spotsfrom(spot)
    retval = []
    vertadds = [0,1]
    horizadds = [0,1]
    if (spot[0] > 1) then vertadds << -1; end
    if (spot[1] > 1) then horizadds << -1; end
    vertadds.each do |v|
      horizadds.each do |h|
        if (v != 0 or h != 0)
          ns = [spot[0] + v, spot[1] + h, ((v*v + h*h)**0.5).round(3)]
          if (@terrain[ns[0]] and @terrain[ns[0]][ns[1]])
            retval << ns
          end
        end
      end
    end
    retval
  end
end
