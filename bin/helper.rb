require 'pathname'
require 'tmpdir'
require 'ostruct'

ENV['BUNDLE_GEMFILE'] = Pathname.new(File.dirname(__FILE__)).join('../Gemfile').to_s
require 'bundler'
Bundler.require

def mktmpdir debug = false
  Dir.mktmpdir do |tmpdir|
    dir = Pathname.new(tmpdir)
    if debug
      dir = Pathname.new(File.dirname(__FILE__)).join('../tmp')
      FileUtils.mkdir dir unless dir.exist?
    end
    yield dir
  end
end

