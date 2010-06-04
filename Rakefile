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
