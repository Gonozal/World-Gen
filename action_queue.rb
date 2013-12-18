module WorldGen
  class ActionQueue
    attr_accessor :queue

    def initialize
      self.queue = []
    end

    def empty?
      self.queue.empty?
    end

    def <<(element)
      unless Hash === element and element.size == 1
        raise ArgumentException "ActionQueue can only contain hashes"
      end
      @queue << element
    end
    alias add <<

    def next
      self.queue.shift
    end
    alias shift next
    alias pop next

    def size
      self.queue.size
    end
    alias length size
  end
end
