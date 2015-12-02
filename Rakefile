require 'rspec/core/rake_task'

desc 'Run specs'
RSpec::Core::RakeTask.new(:spec) do |t|
  # Force load the test_helper to ensure SimpleCov is loaded before the test files
  t.ruby_opts = ['-r "./spec/spec_helper"']
end

task :default => [:spec]

desc "Create yardocs according to .yardopts file"
task :yardoc do
  `yardoc`
end

desc "Add analytics tracking information to yardocs"
task :addanalytics do
tracking_code = <<EOC
<script type="text\/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-3784741-4']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text\/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https:\/\/ssl' : 'http:\/\/www') + '.google-analytics.com\/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
EOC
  files = Dir.glob('./doc/yard/**/*.html').reject { |file| %w{class_list file_list frames.html _index.html method_list}.any? { |skipfile| file.include?(skipfile) }}
  files.each do |file|
    contents = File.read(file)
    writer = File.open(file, 'w')
    writer.write(contents.gsub(/\<\/body\>/, tracking_code + "</body>"))
    writer.flush
  end
end

desc "Upload docs to rubyforge"
task :uploadyardocs => [:yardoc, :addanalytics] do
  `rsync -av doc/yard/* bhuga@rubyforge.org:/var/www/gforge-projects/promise`
end
