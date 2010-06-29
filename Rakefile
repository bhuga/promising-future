require 'spec'
require 'spec/rake/spectask'

desc 'Run specs'
task 'spec' do
  Spec::Rake::SpecTask.new("spec") do |t|
    t.spec_files = FileList["spec/**/*.spec","spec/*.rb"]
    t.rcov = false
    t.spec_opts = ["-c"]
  end
end

desc 'Run specs with backtrace'
task 'tracespec' do
  Spec::Rake::SpecTask.new("tracespec") do |t|
    t.spec_files = FileList["spec/**/*.spec", "spec/*.rb"]
    t.rcov = false
    t.spec_opts = ["-bcfn"]
  end
end

desc 'Run coverage'
task 'coverage' do
  Spec::Rake::SpecTask.new("coverage") do |t|
    t.spec_files = FileList["spec/**/*.spec","spec/*.rb"]
    t.rcov = true
    t.spec_opts = ["-c"]
  end
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
