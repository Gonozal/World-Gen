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
      @path
    else
      return nil
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
        newpath.flatten.each_slice(2) {|i,j| @path << [i,j]}
        return @path
      end
      been_there[spot] = 1

      # puts "spot: #{spot[0]}, #{spot[1]}"
      spotsfrom(spot).each do |newspot|
        next if been_there[newspot[0..1]]
        tcost = @terrain[newspot[0]][newspot[1]] * newspot[2]
        newcost = cost_so_far + tcost
        # print "candidate: #{newspot[0]}, #{newspot[1]}; "
        pqueue << [newcost + estimate(newspot), [newspot,newpath,newcost]]
      end
    end
    return nil
  end

  def estimate(spot)
    x = spot[0]
    y = spot[1]
    (((x - @goal[0]) ** 2 + (y - @goal[1]) ** 2) ** 0.5) * 110 * @terrain[x][y] * 0.01
  end

  def spotsfrom(spot)
    retval = []
    vertadds = [0,1,2]
    horizadds = [0,1,2]
    if (spot[0] > 0) then vertadds << -1; end
    if (spot[0] > 1) then vertadds << -2; end
    if (spot[1] > 0) then horizadds << -1; end
    if (spot[1] > 1) then horizadds << -2; end
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
