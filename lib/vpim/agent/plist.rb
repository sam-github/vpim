# http://www2a.biglobe.ne.jp/~seki/ruby/src/plist.rb
require 'rexml/document'
require 'time'

class Plist #:nodoc:
   def self.file_to_plist(fname)
     File.open(fname) do |fp|
       doc = REXML::Document.new(fp)
       return self.new.visit(REXML::XPath.match(doc, '/plist/')[0])
     end
   end

   def initialize
     setup_method_table
   end

   def visit(node)
     visit_one(node.elements[1])
   end

   def visit_one(node)
     choose_method(node.name).call(node)
   end

   def visit_null(node)
     p node if $DEBUG
     nil
   end

   def visit_dict(node)
     dict = {}
     es =  node.elements.to_a
     while key = es.shift
       next unless key.name == 'key'
       dict[key.text] = visit_one(es.shift)
     end
     dict
   end

   def visit_array(node)
     node.elements.collect do |x|
       visit_one(x)
     end
   end

   def visit_integer(node)
     node.text.to_i
   end

   def visit_real(node)
     node.text.to_f
   end

   def visit_string(node)
     node.text.to_s
   end

   def visit_date(node)
     Time.parse(node.text.to_s)
   end

   def visit_true(node)
     true
   end

   def visit_false(node)
     false
   end

   private
   def choose_method(name)
     @method.fetch(name, method(:visit_null))
   end

   def setup_method_table
     @method = {}
     @method['dict'] = method(:visit_dict)
     @method['integer'] = method(:visit_integer)
     @method['real'] = method(:visit_real)
     @method['string'] = method(:visit_string)
     @method['date'] = method(:visit_date)
     @method['true'] = method(:visit_true)
     @method['false'] = method(:visit_false)
     @method['array'] = method(:visit_array)
   end
end
