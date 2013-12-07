module WorldGen
  class Vector
    include Enumerable
    include Comparable

    attr_reader :elements
    protected :elements
    private_class_method :new

    def initialize(array)
      @elements = array
    end

    def <=>(an_other)
      each2(an_other) do |e1, e2|
        return e1 <=> e2 unless e1 == e2
      end
    end

    def Vector.[](*array)
      new convert_to_array(array, false)
    end


    def Vector.elements(array, copy = true)
      new convert_to_array(array, copy)
    end

    # Returns the normal Vector (2D only)
    def normal_vector
      Vector.elements([- @elements[1], @elements[0]], false)
    end

    def to_i
      Vector.elements([@elements[0].to_i, @elements[1].to_i])
    end

    def round(digits = 0)
      Vector.elements([@elements[0].round(digits), @elements[1].round(digits)])
    end

    def [](i)
      @elements[i]
    end

    def []=(i, v)
      @elements[i] = v
    end

    def size
      @elements.size
    end

    def each(&block)
      return to_enum(:each) unless block_given?
      @elements.each(&block)
      self
    end

    #
    # Iterate over the elements of this vector and +v+ in conjunction.
    #
    def each2(v) # :yield: e1, e2
      raise TypeError, "Integer is not like Vector" if v.kind_of?(Integer)
      return to_enum(:each2, v) unless block_given?
      size.times do |i|
        yield @elements[i], v[i]
      end
      self
    end

    #
    # Collects (as in Enumerable#collect) over the elements of this vector and +v+
    # in conjunction.
    #
    def collect2(v) # :yield: e1, e2
      raise TypeError, "Integer is not like Vector" if v.kind_of?(Integer)
      return to_enum(:collect2, v) unless block_given?
      Array.new(size) do |i|
        yield @elements[i], v[i]
      end
    end

    def *(x)
      case x
      when Numeric
        els = @elements.collect{|e| e * x}
        self.class.elements(els, false)
      when Vector
        p = 0
          each2(x) {|v1, v2|
            p += v1 * v2.conj
          }
        p
      end
    end

    def +(v)
      case v
      when Vector
        els = collect2(v) {|v1, v2|
          v1 + v2
        }
        self.class.elements(els, false)
      end
    end

    def -(v)
      case v
      when Vector
        els = collect2(v) {|v1, v2|
          v1 - v2
        }
        self.class.elements(els, false)
      end
    end

    def /(x)
      case x
      when Numeric
        els = @elements.collect{|e| e / x}
        self.class.elements(els, false)
      end
    end

    def to_s
      "Vector[" + @elements.join(", ") + "]"
    end

    def inspect
      "Vector" + @elements.inspect
    end

    def collect(&block) # :yield: e
      return to_enum(:collect) unless block_given?
      els = @elements.collect(&block)
      self.class.elements(els, false)
    end
    alias map collect

    #
    # Returns the modulus (Pythagorean distance) of the vector.
    #   Vector[5,8,2].r => 9.643650761
    #
    def magnitude
      Math.sqrt(@elements.inject(0) {|v, e| v + e.abs2})
    end

    def normalize
      n = magnitude
      raise ZeroVectorError, "Zero vectors can not be normalized" if n == 0
      self / n
    end

    # Converts the obj to an Array. If copy is set to true
    # a copy of obj will be made if necessary.
    def self.convert_to_array(obj, copy = false)
      case obj
      when Array
        copy ? obj.dup : obj
      when Vector
        obj.to_a
      else
        begin
          converted = obj.to_ary
        rescue Exception => e
          raise TypeError, "can't convert #{obj.class} into an Array (#{e.message})"
        end
        raise TypeError, "#{obj.class}#to_ary should return an Array" unless converted.is_a? Array
        converted
      end
    end

    def ==(other)
      return false unless Vector === other
      @elements == other.elements
    end

    def eql?(other)
      return false unless Vector === other
      @elements.eql? other.elements
    end

    def clone
      self.class.elements(@elements)
    end

    def convert_to_array(obj, copy = false) # :nodoc:
      case obj
      when Array
        copy ? obj.dup : obj
      when Vector
        obj.to_a
      else
        begin
          converted = obj.to_ary
        rescue Exception => e
          raise TypeError, "can't convert #{obj.class} into an Array (#{e.message})"
        end
        raise TypeError, "#{obj.class}#to_ary should return an Array" unless converted.is_a? Array
        converted
      end
    end
  end
end

