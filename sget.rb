require 'pry'
$downloaded_files = {}
$depth = 1
$dir = "./"
$total = 0
$success = 0
$timeout = 30
$url = ""

def main
	begin
		ARGV.each_with_index do |a, i|
			$depth = ARGV[i + 1].to_i if a == "-d"
			raise Exception.new('Max Depth is 5') if $depth.to_i > 5
			$dir = ARGV[i + 1] if a == "-f"
			$timeout = ARGV[i + 1] if a == "-t"
		end
		$url = ARGV.last
		download($url, 0)
		puts "#{$success}/#{$total} files successfully downloaded."
	rescue Exception => msg
		puts msg
	end
end

def download(filename, level)
	return false if level > $depth
	if $downloaded_files.has_key? filename
		status = $downloaded_files[filename]
		puts "#{"  "*level} #{filename} [#{if status == 0 then "success" else "fail: #{status}" end}]"
	elsif filename.start_with? $url
		$total += 1
		command = "wget -T #{$timeout} '#{filename}' #{'--directory-prefix='+$dir if $dir != "./"} 2>&1 | sed -n 's/.*‘\\(.*\\)’ saved.*/\\1/p'"
		saved_file = `#{command}`
		saved_file = saved_file.strip
		status = $?.exitstatus
		puts "#{"  "*level} #{saved_file} [#{if status == 0 then "success" else "fail: #{status}" end}]"
		$downloaded_files[filename] = status
		if status == 0
			$success += 1
			if [".php", ".html", ".htm"].include? File.extname(saved_file)
				str = File.read( saved_file )
				newstr = str.gsub(/<a.*?href="(.*?)".*?\/a>/) do |tag|
					if download($1, level+1)
						tag.gsub!($1, $dir + "/" + $1.split("/").last)
					else
						tag
					end
				end
				File.write(saved_file, newstr)
			end
		end
	else
		puts "#{"  "*level} #{filename} [external]"
	end
	return status
end

main
