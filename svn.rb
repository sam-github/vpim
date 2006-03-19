module Svn
  def Svn.info
    info = {}
    IO.popen("svn info") do |io|
      io.each do |line|
        if line =~ /^([^:]+): (.*)/
          info[$1] = $2
        end
      end
    end
    info
  end
end

