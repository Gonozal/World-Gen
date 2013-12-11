module WorldGen
  class SvgPath
    attr_accessor :path, :parsed

    def initialize(params)
      params.each do |key, val|
        send "#{key}=".to_sym, val
      end
      parse unless path.blank?
    end

    def parse
      self.parsed = path.scan(/([\- ]?\w[\- ]?)([0-9.,\- ]+)/).map do |e|
        [e[0], e[1].scan( /([0-9.]+|[, \-])/ ).map{|se| se.first}]
      end
    end

    def offset(offset)
      parsed.each do |e|
        
      end
    end

    def to_s
      parsed.flatten.inject(""){|str, e| str << e}
    end
  end
end
