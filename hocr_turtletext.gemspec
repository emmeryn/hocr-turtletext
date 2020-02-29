
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hocr_turtletext/version'

Gem::Specification.new do |spec|
  spec.name          = 'hocr_turtletext'
  spec.version       = HocrTurtletext::VERSION
  spec.authors       = ['Sue Zheng Hao']

  spec.summary       = 'Reads structured text from hOCR input.'
  spec.description   = <<-DESC
  Parses hOCR input and provides methods to access text in a structured manner. Typical use
  cases include parsing formatted text from a hOCR file produced by running a document
  through OCR.
  DESC
  spec.homepage      = 'https://github.com/emmeryn/hocr-turtletext'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise 'RubyGems 2.0 or newer is required to protect against ' \
  #     'public gem pushes.'
  # end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_runtime_dependency 'nokogiri', '~> 1.10', '>= 1.10.7'
end
