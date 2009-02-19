require 'test/unit'
require 'pp'

module Enumerable
  unless self.methods.include? :count
    def count
      self.inject(0){|i,_| i + 1}
    end
  end
end

