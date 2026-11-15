require 'bundler/setup'

spec = Gem.loaded_specs.fetch('fastlane')
abort 'Unexpected locked Fastlane version' unless spec.version.to_s == '2.241.2'
path = File.join(spec.full_gem_path, 'match/lib/match/table_printer.rb')
needle = 'puts(Terminal::Table.new(params))'
marker = '# Match table output suppressed by reviewed homelab guard'
body = File.binread(path)

if body.scan(needle).length == 2 && !body.include?(marker)
  stage = "#{path}.suppression-#{Process.pid}"
  begin
    File.write(stage, body.gsub(needle, marker))
    File.chmod(File.stat(path).mode & 0o777, stage)
    File.rename(stage, path)
  ensure
    File.delete(stage) if File.exist?(stage)
  end
elsif body.scan(needle).empty? && body.scan(marker).length == 2
  # Already patched in this job's locked gem installation.
else
  abort 'Unexpected Match table implementation; suppression not established'
end

checked = File.binread(path)
abort 'Match table suppression verification failed' unless checked.scan(needle).empty? && checked.scan(marker).length == 2
puts 'Locked Fastlane Match table suppression verified.'
