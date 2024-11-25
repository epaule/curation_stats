#!/usr/bin/env crystal
# uses Heng Li's fasta parser from Klib
# uses a contamination BED file to strip out sequences from a fasta

require "option_parser"
require "klib"

include Klib

con_file = ""
fasta = ""

OptionParser.parse do |parser|
  parser.banner = "Usage: curation_stats --contamination CONTAMINATION_FILE --fasta FASTAFILE"
  parser.on("-f FASTA_FILE", "--fasta=FASTA_FILE", "FASTA file (can be compressed)") { |filename| fasta = filename }
  parser.on("-c CONTAMINATION_BED_FILE", "--contamination=CONTAMINATION_BED_FILE", "contamination BED file") { |filename| con_file = filename }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

def parse_decon_file(f)
  i = [] of String
  File.each_line(f) do |line|
    if /^(\S+)\s+\d+\s+\d+\s+REMOVE/i.match(line)
      i << $1
    end
  end
  i
end

ids = parse_decon_file(con_file)

if File.exists?(fasta)
  fp = GzipReader.new(fasta)
  fx = FastxReader.new(fp)
  cleaned_fasta = File.new("#{fasta}_cleaned", "w")

  fx.each { |entry|
    unless ids.includes? entry.name
      cleaned_fasta.puts ">#{entry.name}"
      entry.seq.scan(/.{1,60}/).each { |line| cleaned_fasta.puts line[0] }
    end
  }
end
