#!/usr/bin/env ruby
require 'bundler/inline'

gemfile do
  source "https://rubygems.org"
  gem "rugged", "1.1.0", submodules: true
end

p Rugged::Repository.new(Dir.pwd)
