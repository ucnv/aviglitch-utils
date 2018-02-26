#!/usr/bin/env ruby
# encoding: utf-8
require File.expand_path '../helper.rb', $0

doc = <<-DOC.gsub '__FILE__', File.basename($0)
Crush the image tight into given video frame aspect. It gives effects like bleeding.

Usage:
  __FILE__ <infile> [-r <ratio> -b <file> --raw] -o <outfile>  [--debug]
  __FILE__ -h | --help

Options:
  -o <outfile>   Set output file name.
  -b <file>      Set a first frame image. JPEG or PNG.
  -r <ratio>     Set how small to crush (given number part of) [default: 5].
  --raw          Keep output as no-keyframe avi [default: false].
  --debug        Flag for debugging [default: false].
  -h --help      Show this screen.
DOC

begin
  options = Docopt::docopt doc
  mktmpdir(options['--debug']) do |tmpdir|
    infile = options['<infile>']
    cmd = Terrapin::CommandLine.new 'ffmpeg', '-i :infile 2>&1', :expected_outcodes => [0, 1]
    info = cmd.run infile: infile
    size = (info =~ /(\d{3,})x(\d{3,})/) ? [$1.to_i, $2.to_i] : [1024, 768]
    fps = (info =~ /, ([\.\d]*) fp/) ? $1 : 24
    bfile = infile
    if options['-b']
      bfile = options['-b']
      cmd = Terrapin::CommandLine.new 'ffmpeg', '-loop 1 -f image2 -i :infile -c:v mpeg4 -y -q:v 0 -r :fps -t 0.5 -an :outfile'
    else
      cmd = Terrapin::CommandLine.new 'ffmpeg', '-i :infile -c:v mpeg4 -y -q:v 0 -t 0.5 -r :fps -an :outfile'
    end
    basefile = tmpdir.join('base.avi')
    cmd.run infile: bfile, outfile: basefile.to_s, fps: fps

    cmd = Terrapin::CommandLine.new 'ffmpeg', '-i :infile -c:v mpeg4 -y -q:v 0 -vf scale=:scale -an :outfile'
    avifile = tmpdir.join('mpeg4resized.avi')
    size.collect! {|x| x / options['-r'].to_f }
    cmd.run infile: infile, outfile: avifile.to_s, scale: ("%d:%d" % size)

    datamoshed = AviGlitch.open avifile
    datamoshed.remove_all_keyframes!

    base = AviGlitch.open basefile
    base.mutate_keyframes_into_deltaframes!
    base.frames.concat datamoshed.frames
    datamoshed.close

    glitchfile = tmpdir.join 'glitch.avi'
    base.output glitchfile
    if options['--raw']
      cmd = Terrapin::CommandLine.new 'cp', ':infile :outfile'
    else
      cmd = Terrapin::CommandLine.new 'ffmpeg', '-i :infile -an -q:v 0 -y :outfile'
    end
    cmd.run infile: glitchfile.to_s, outfile: options['-o']
  end
rescue Docopt::Exit => e
  puts e.message
end
