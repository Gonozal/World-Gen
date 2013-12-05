module WorldGen
  class Street
    attr_accessor :path

    def initialize(params = {})
      self.path = params[:path]
    end
  end
end
