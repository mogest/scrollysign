spec = Gem::Specification.new do |s|
  s.name = 'scrollysign'
  s.version = '1.0.0'
  s.summary = "Driver to write to Adaptive LED signs"
  s.description = s.summary
  s.files = [] + Dir['lib/**/*.rb']
  s.require_path = 'lib'
  s.add_runtime_dependency "ruby-serialport"
  s.has_rdoc = false
  s.author = "Roger Nesbitt"
  s.email = "roger@youdo.co.nz"
end
