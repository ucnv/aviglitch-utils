#!/usr/bin/env ruby
# encoding: utf-8
require File.expand_path '../helper.rb', $0

doc = <<-DOC.gsub '__FILE__', File.basename($0)
Glitch with SNOW codec.

Usage:
  __FILE__ <infile> [-s <n> -d <n> --debug] -o <outfile>
  __FILE__ -h | --help

Options:
  -o <outfile>  Set output file name.
  -s <n>        Set start position of the video by seconds.
  -d <n>        Set duration of the result video by seconds.
  --debug       Flag for debugging [default: false].
  -h --help     Show this screen.
DOC

begin
  options = Docopt::docopt doc
  mktmpdir(options['--debug']) do |tmpdir|
    other_options = ''
    other_options += ' -ss ' + options['-s'] if options['-s']
    other_options += ' -t ' + options['-d'] if options['-d']
    cmd = Terrapin::CommandLine.new 'ffmpeg', '-i :infile %s -strict -2 -c:v snow -pix_fmt yuv420p -y -q:v 1 -an :outfile' % other_options
    snowfile = tmpdir.join('snow.avi')
    cmd.run infile: options['<infile>'], outfile: snowfile.to_s
    a = AviGlitch.open snowfile
    a.glitch :keyframe do |f|
      f.gsub rand(10).to_s, 'a'
    end
    glitchfile = tmpdir.join 'glitch.avi'
    a.output glitchfile
    cmd = Terrapin::CommandLine.new 'ffmpeg', '-i :infile -an -q:v 0 -y :outfile'
    cmd.run infile: glitchfile.to_s, outfile: options['-o']
  end
rescue Docopt::Exit => e
  puts e.message
end
