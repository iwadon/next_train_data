# -*- coding: utf-8 -*-
require 'open-uri'
require 'optparse'
require 'nokogiri'

def usage
  puts(ARGV.options)
  exit(1)
end

output_filename = nil
ARGV.options.banner << <<EOL
 URI
名古屋市バスの時刻表ページを解析して、NextTrain形式のテキストとして出力します。
Options:
EOL
ARGV.options do |q|
  q.on('-o FILE', '--output-file=FILE', '出力ファイル名の指定') do |v|
    output_filename = v
  end
  q.parse!
end || usage
usage if ARGV.empty?
output_file = if output_filename
                File.open(output_filename, 'w')
              else
                STDOUT
              end
doc = Nokogiri(open(ARGV[0]))
title = doc.xpath(".//table[3]/tr/td/b").text
marks = {"無印" => "a", "〇" => "b", '△' => 'c'}
attrs = doc.xpath(".//table[3]/tr/td").text.scan(/^(\S+)・・・([^\n]+)$/).map do |a, b|
  [marks[a] || a, b]
end
times = [[], [], []]
doc.xpath(".//table[5]/tr").each do |e|
  ary2 = []
  e.children.each do |c|
    next if c.text == "\n"
    ary2 << c.text
  end
  times[0] << ary2[0, 2]
  times[1] << ary2[2, 2]
  times[2] << ary2[4, 2]
end
output_file.puts("\##{title}")
attrs.each do |k, v|
  output_file.puts("#{k}:#{v}")
end
days = {"平日" => "[MON][TUE][WED][THU][FRI]", "土曜" => "[SAT]", "日曜・休日" => "[SUN]"}
m = Regexp.new("[#{marks.keys.join('').sub(/無印/, '\ ')}]?\\d\\d", nil, 'u')
times.each do |times2|
  output_file.puts(days[times2.shift[1]])
  times2.each do |k, v|
    output_file.printf("%02d: ", k.to_i)
    output_file.puts(v.scan(m).map do |t|
                       marks.find do |kk, vv|
                         t.sub!(/^#{kk}/, vv)
                       end || t.replace("a#{t}")
                       t
                     end.join(' '))
  end
end
