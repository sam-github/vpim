require 'benchmark'
require 'pp'

str0 = "a" * 20
str1 = str0.upcase
sym0 = str0.to_sym
sym1 = str1.to_sym

$N = 1000000

Benchmark.bm(20) do |x|

  x.report("noop")  do
    $N.times do
    end
  end

  x.report("String#==")  do
    $N.times do
      str0 == str1
    end
  end

  x.report("String#casecmp")  do
    $N.times do
      str0.casecmp(str1)
    end
  end

  x.report("Symbol#==")  do
    $N.times do
      sym0 == sym1
    end
  end

  x.report("String#to_sym")  do
    $N.times do
      str1.to_sym
    end
  end

  x.report("String#up")  do
    $N.times do
      str1.upcase
    end
  end

  x.report("String#up#to_sym")  do
    $N.times do
      str1.upcase.to_sym
    end
  end

end

