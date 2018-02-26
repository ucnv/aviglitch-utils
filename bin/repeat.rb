#!/usr/bin/env ruby
# encoding: utf-8
require File.expand_path '../helper.rb', $0

doc = <<-DOC.gsub '__FILE__', File.basename($0)
Repeat a frame.

Usage:
  __FILE__ <infile> [-s <start> -t <duration> --decap --raw] -o <outfile>  [--debug]
  __FILE__ -h | --help

Options:
  -o <outfile>   Set output file name.
  -s <start>     Set begining position of repeating as sec [default: 0].
  -t <duration>  Set duration of repeating frames as sec [default: 3].
  --raw          Keep output as no-keyframe avi [default: false].
  --decap        Remain repeated frames only [default: false].
  --debug        Flag for debugging [default: false].
  -h --help      Show this screen.
DOC

begin
  options = Docopt::docopt doc
  mktmpdir(options['--debug']) do |tmpdir|
    cmd = Terrapin::CommandLine.new 'ffmpeg', '-i :infile -c:v mpeg4 -y -q:v 0 -an :outfile'
    infile = options['<infile>']
    avifile = tmpdir.join('mpeg4.avi')
    cmd.run infile: infile, outfile: avifile.to_s
    cmd = Terrapin::CommandLine.new 'ffmpeg', '-i :infile 2>&1', :expected_outcodes => [0, 1]
    info = cmd.run infile: avifile.to_s
    fps = (info =~ /, ([\.\d]*) fp/) ? $1 : 24
    start_at = (fps.to_f * options['-s'].to_f).to_i
    duration = (fps.to_f * options['-t'].to_f).to_i
    a = AviGlitch.open avifile
    start_at += 1 if a.frames[start_at].is_keyframe?
    repeated = a.frames[start_at, 1] * duration
    if !options['--decap']
      base = a.frames[0..start_at].mutate_keyframes_into_deltaframes!
      repeated = base.concat repeated
    end
    glitchfile = tmpdir.join 'glitch.avi'
    repeated.to_avi.output glitchfile
    if options['--raw']
      cmd = Terrapin::CommandLine.new 'cp', ':infile :outfile'
    else
      cmd = Terrapin::CommandLine.new 'ffmpeg', '-i :infile -an -q:v 0 :outfile'
    end
    cmd.run infile: glitchfile.to_s, outfile: options['-o']
  end
rescue Docopt::Exit => e
  puts e.message
end
