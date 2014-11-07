#!/usr/bin/env ruby
# encoding: utf-8
require File.expand_path '../helper.rb', $0

doc = <<-DOC.gsub '__FILE__', File.basename($0)
Make multiple files into datamoshing and concatenate them into one movie.

Usage:
  __FILE__ <infile>... -o <outfile>  [--debug]
  __FILE__ -h | --help

Options:
  -o <outfile>  Set output file name.
  --debug       Flag for debugging [default: false].
  -h --help     Show this screen.
DOC

begin
  options = Docopt::docopt doc
  mktmpdir(options['--debug']) do |tmpdir|
    cmd = Cocaine::CommandLine.new 'ffmpeg', '-i :infile -c:v mpeg4 -y -q:v 0 -an :outfile'
    avi = nil
    options['<infile>'].each.with_index do |infile, i|
      avifile = tmpdir.join('mpeg4.avi')
      cmd.run infile: infile, outfile: avifile.to_s
      a = AviGlitch.open avifile
      unless i == 0
        a.glitch :keyframe do |f|
          ''
        end
      end
      a.mutate_keyframes_into_deltaframes!
      if avi.nil?
        avi = a
      else
        avi.frames.concat a.frames
        a.close
      end
    end
    glitchfile = tmpdir.join 'glitch.avi'
    avi.output glitchfile
    cmd = Cocaine::CommandLine.new 'ffmpeg', '-i :infile -an -q:v 0 :outfile'
    cmd.run infile: glitchfile.to_s, outfile: options['-o']
  end
rescue Docopt::Exit => e
  puts e.message
end
