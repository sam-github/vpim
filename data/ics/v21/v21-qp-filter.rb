
qp = false

$stdin.each do |line|
  if line =~ /;ENCODING=QUOTED-PRINTABLE[:;].*=$/
    qp = true
    line.gsub!(/=$/, '')
  elsif qp
     $stdout << ' '
    if line =~ /=$/
      # qp continues
      line.gsub!(/=$/, '')
    else
      qp = false
    end
  end

  $stdout << line

  # When we see the beginning of 
  if line =~ /;ENCODING=QUOTED-PRINTABLE[:;].*=$/
  end
end


