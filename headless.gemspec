Gem::Specification.new do |s|
  s.authors = ['Leonid Shevtsov', 'Igor Afonov', 'Paul Geraghty']
  s.email = 'muse@appsthatcould.be'

  s.name = 'headless-muse'
  s.version = '1.1.0'
  s.summary = 'Ruby headless display interface'

  s.description = <<-EOF
    Headless is a Ruby interface for Xvfb. It allows you to create a headless display straight from Ruby code, hiding some low-level action.
    It can also capture video and audio via ffmpeg and take screenshots.
  EOF
  s.requirements = 'Xvfb'
  s.homepage = 'https://github.com/pgeraghty/headless'

  s.files         = `git ls-files`.split("\n")

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2.6'
  s.add_development_dependency('coveralls', '> 0') unless RUBY_VERSION == '1.8.7'
end
