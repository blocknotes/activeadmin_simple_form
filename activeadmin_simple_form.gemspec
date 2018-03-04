lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activeadmin/simple_form/version'

Gem::Specification.new do |spec|
  spec.name          = 'activeadmin_simple_form'
  spec.version       = ActiveAdmin::SimpleForm::VERSION
  spec.summary       = 'simple_form for ActiveAdmin'
  spec.description   = 'An Active Admin plugin to use Simple Form in place of Formtastic in edit views'
  spec.license       = 'MIT'
  spec.authors       = ['Mattia Roccoberton']
  spec.email         = 'mat@blocknot.es'
  spec.homepage      = 'https://github.com/blocknotes/activeadmin_simple_form'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'activeadmin', '~> 1.0'
  spec.add_runtime_dependency 'simple_form', '~> 3.5'
end
