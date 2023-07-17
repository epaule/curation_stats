#!/usr/bin/env crystal
# uses Heng Li's fasta parser from Klib

require "option_parser"
require "klib"

include Klib

fasta = ""

OptionParser.parse do |parser|
  parser.banner = "Usage: curates_90 --fasta FASTAFILE"
  parser.on("-f FASTA_FILE", "--fasta=FASTA_FILE", "FASTA file of the assembly (can be compressed)") { |f| fasta = f }
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

fp = GzipReader.new(fasta)
fx = FastxReader.new(fp)

total_bp = 0_u64
curated_bp = 0_u64

fx.each { |e|
  total_bp += e.seq.size

  if e.name[0..6].downcase == "super_"
    curated_bp += e.seq.size
  end
}

puts <<-HERE
curated basepairs	#{curated_bp}/#{total_bp} (#{sprintf("%.2f", curated_bp/total_bp*100)}%)
HERE
