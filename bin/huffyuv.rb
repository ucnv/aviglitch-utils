#!/usr/bin/env ruby
# encoding: utf-8
require File.expand_path '../helper.rb', $0

doc = <<-DOC.gsub '__FILE__', File.basename($0)
Glitch with Huffyuv codec.

Usage:
  __FILE__ <infile> [-s <n> -d <n> -h <n> -r <n-m> --raw] -o <outfile> [--debug]
  __FILE__ -h | --help

Options:
  -o <outfile>  Set output file name.
  -d <n>        Set video duration in seconds. It is preferred to be less than 60s. [default: 30].
  -r <n-m>      Set range in height of the glitch effect. It should be between 0 and 1. Or you can set increase-decrease value like "0.1-0.9" [default: 0.99].
  -s <n>        Set start position of the video by seconds.
  --raw         Keep output as damaged avi [default: false].
  --debug       Flag for debugging [default: false].
  -h --help     Show this screen.
DOC

begin
  options = Docopt::docopt doc
  mktmpdir(options['--debug']) do |tmpdir|
    other_options = ''
    other_options += ' -t ' + options['-d']
    other_options += ' -ss ' + options['-s'] if options['-s']
    cmd = Terrapin::CommandLine.new 'ffmpeg', '-i :infile %s -c:v huffyuv -pix_fmt yuv422p -y -q:v 0 -an :outfile' % other_options
    huffyuvfile = tmpdir.join('huffyuv.avi')
    cmd.run infile: options['<infile>'], outfile: huffyuvfile.to_s
    a = AviGlitch.open huffyuvfile
    l = a.frames.size.to_f
    pos = options['-r'].split '-'
    pos[1] = pos[0] if pos[1].nil?
    sp, ep = pos.collect {|p| p.to_f }
    a.glitch_with_index do |f, i|
      p = i / l
      ratio = (ep - sp) * p + sp
      f[0, (1 - ratio) * f.size]
    end
    glitchfile = tmpdir.join 'glitch.avi'
    a.output glitchfile
    if options['--raw']
      cmd = Terrapin::CommandLine.new 'cp', ':infile :outfile'
    else
      cmd = Terrapin::CommandLine.new 'ffmpeg', '-i :infile -an -q:v 0 -c:v mpeg4 -y :outfile'
    end
    cmd.run infile: glitchfile.to_s, outfile: options['-o']
  end
rescue Docopt::Exit => e
  puts e.message
end
