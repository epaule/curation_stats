#!/usr/bin/env crystal
# uses Heng Li's fasta parser from Klib

require "option_parser"
require "klib"

include Klib

con_file = ""
bed_file = ""
fasta = ""

OptionParser.parse do |parser|
  parser.banner = "Usage: curation_stats --contamination CONTAMINATION_FILE --fasta FASTAFILE"
  parser.on("-f FASTA_FILE", "--fasta=FASTA_FILE", "FASTA file of the assembly (can be compressed)") { |filename| fasta = filename }
  parser.on("-c CONTAMINATION_FILE", "--contamination=CONTAMINATION_FILE", "contamination file") { |filename| con_file = filename }
  parser.on("-b CONTAMINATION_BED_FILE", "--contamination_bed=CONTAMINATION_BED_FILE", "contamination BED file") { |filename| bed_file = filename }
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
    if /^REMOVE\s+(\S+)/i.match(line)
      i << $1
    end
  end
  i
end

def parse_decon_bed_file(f)
  i = [] of String
  File.each_line(f) do |line|
    if /^(\S+)\s+\d+\s+\d+\s+REMOVE/i.match(line)
      i << $1
    end
  end
  i
end

ids = [] of String

if !con_file.blank?
  ids = parse_decon_file(con_file)
elsif !bed_file.blank?
  ids = parse_decon_bed_file(bed_file)
end

fp = GzipReader.new(fasta)
fx = FastxReader.new(fp)

total_bp = 0_u64
total_seq = 0_u64
contaminated_bp = 0_u64
contaminated_seq = 0_u64

fx.each { |e|
  total_bp += e.seq.size
  total_seq += 1

  if ids.includes? e.name
    contaminated_bp += e.seq.size
    contaminated_seq += 1
  end
}

puts <<-HERE
contaminated basepairs	#{contaminated_bp}/#{total_bp} (#{sprintf("%.2f", contaminated_bp/total_bp*100)}%)
contaminated sequences	#{contaminated_seq}/#{total_seq} (#{sprintf("%.2f", contaminated_seq/total_seq*100)}%)
HERE
