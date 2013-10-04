
def info(spec)
  {
    :author => "Sam Roberts",
    :email => "vieuxtech@gmail.com",
    :homepage => "http://vpim.rubyforge.org",
    :rubyforge_project => "vpim",
  }.each do |key, value|
    spec.send(key.to_s + "=", value)
  end
end

