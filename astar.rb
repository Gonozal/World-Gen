require 'enumerator'
require 'benchmark'

# I suppose someone would think I should use a heap here.
# I've found that the built-in sort method is much faster
# than any heap implementation in ruby.  As a plus, the logic
# is easier to follow.
class PriorityQueue
  def initialize
    @list = []
  end

  def add(priority, item)
    # Add @list.length so that sort is always using Fixnum comparisons,
    # which should be fast, rather than whatever is comparison on `item'
    # @list << [priority, @list.length, item]
    i2 = 0
    @list.each_with_index do |l, i|
      i2 = i
      next if l.first < priority
      break
    end
    @list.insert(i2, [priority, @list.length, item])
    # @list.sort!
    self
  end
  def <<(pritem)
    add(*pritem)
  end
  def next
    @list.shift[2]
  end
  def empty?
    @list.empty?
  end
end

class Astar
  def benchmark(params)
    Benchmark.bmbm(10) do |results|
      results.report("sorted array") do
        do_quiz_solution params
      end
    end
  end

  def do_quiz_solution(params = {})
    @terrain = params[:terrain]
    @start = params[:start]
    @goal = params[:goal]
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
      spotsfrom(spot).each {|newspot|
        next if been_there[newspot[0..1]]
        tcost = @terrain[newspot[0]][newspot[1]] * newspot[2]
        newcost = cost_so_far + tcost
        pqueue << [newcost + estimate(newspot), [newspot,newpath,newcost]]
      }
    end
    return nil
  end

  def estimate(spot)
    (((spot[0] - @goal[0]) ** 2 + (spot[1] - @goal[1]) ** 2) ** 0.5).round
  end

  def spotsfrom(spot)
    retval = []
    vertadds = [0,1]
    horizadds = [0,1]
    if (spot[0] > 0) then vertadds << -1; end
    if (spot[1] > 0) then horizadds << -1; end
    vertadds.each{|v| horizadds.each{|h|
        if (v != 0 or h != 0) then
          ns = [spot[0] + v, spot[1] + h, ((h + v) % 2 == 0)? 1.41 : 0]
          if (@terrain[ns[0]] and @terrain[ns[0]][ns[1]]) then
            retval << ns
          end
        end
      }}
    retval
  end
end
