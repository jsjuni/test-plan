require 'fileutils'

task :default => %w[
  configurations_graph
  unoptimized_visualizations
  optimized_visualizations
  test_docs
  schedules
]

# Generate quantities

task :quantities => 'quantities.json'

file 'quantities.json' do |t|
  system "ruby generate-quantities.rb > #{t.name}"
end

# Generate scenarios

task :scenarios => 'scenarios.json'

file 'scenarios.json' do |t|
  system "ruby generate-scenarios.rb > #{t.name}"
end

# Generate requirements

task :requirements => 'requirements.json'

file 'requirements.json' => %w[quantities.json scenarios.json] do |t|
  t.prerequisites.delete('quantities.json')
  t.prerequisites.delete('scenarios.json')
  system "ruby -I. generate-requirements.rb --quantities quantities.json --scenarios scenarios.json #{t.prerequisites.join(' ')} > #{t.name}"
end

# Substitute scenario proxies.

task :substitute_proxies => %w[requirements-proxied.json]

file 'requirements-proxied.json' => %w[requirements.json proxy-map.json] do |t|
  t.prerequisites.delete('proxy-map.json')
  system "ruby substitute-proxies.rb --proxy-map proxy-map.json #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate scaled cost map

task :costs => 'costs.json'

file 'costs.json' => %w[quantities.json scenarios.json] do |t|
  t.prerequisites.delete('quantities.json')
  t.prerequisites.delete('scenarios.json')
  system "ruby -I. generate-costs.rb --quantities quantities.json --scenarios scenarios.json #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate tests

task :tests => 'tests.json'

file 'requirements-summary.json' => %w[tests.json]

file 'tests.json' => %w[requirements-proxied.json] do |t|
  system "ruby -I. generate-tests.rb --graph configurations-graph.json" +
         " --summary requirements-summary.json" +
         " #{t.prerequisites.join(' ')} > #{t.name}"
end

# Visualize configurations graph

task :configurations_graph => 'configurations-graph.svg'

file 'configurations-graph.json' => %w[tests.json]

file 'configurations-graph.dot' => %w[configurations-graph.json] do |t|
  system "ruby graph-to-dot.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'configurations-graph.svg' => %w[configurations-graph.dot] do |t|
  system "dot -Tsvg #{t.prerequisites.join(' ')} > #{t.name}"
end

# Re-proxy with different proxy map

task :reproxy do
  FileUtils.rm_f(%w[requirements-proxied.json])
  Rake::Task[:substitute_proxies].invoke
  Rake::Task[:sufficient].invoke
end

# Generate (random) sufficiency assertions.

task :sufficient => %w[sufficient-least.json sufficient-least-1.json sufficient-most.json sufficient-most-1.json sufficient-random.json sufficient-none.json]

file 'sufficient-least.json' => %w[requirements-summary.json] do |t|
  system "ruby generate-sufficiency.rb --p-least 1.0 --seed 0 #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'sufficient-least-1.json' => %w[requirements-summary.json] do |t|
  system "ruby generate-sufficiency.rb --p-least 1.0 --max 1 --seed 0 #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'sufficient-most.json' => %w[requirements-summary.json] do |t|
  system "ruby generate-sufficiency.rb --p-least 0.0 --seed 0 #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'sufficient-most-1.json' => %w[requirements-summary.json] do |t|
  system "ruby generate-sufficiency.rb --p-least 0.0 --max 1 --seed 0 #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'sufficient-random.json' => %w[requirements-summary.json] do |t|
  system "ruby generate-sufficiency.rb --p-least 0.5 --seed 0 #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'sufficient-none.json' => %w[requirements-summary.json] do |t|
  system "cat #{t.prerequisites.join(' ')} > #{t.name}"
end

# Prune tests using sufficiency assertions

task :pruned_tests => %w[tests-pruned.json]
task :pruned_tests => :sufficient

file 'tests-pruned.json' => %w[tests.json sufficient.json] do |t|
  t.prerequisites.delete('sufficient.json')
  system "ruby prune-tests.rb --sufficiency sufficient.json #{t.prerequisites.join(' ')} > #{t.name}"
end

# Re-prune with different sufficiency symlink

task :reprune do
  FileUtils.rm_f('tests-pruned.json')
  Rake::Task[:pruned_tests].invoke
end

# Filter test subsets

task :filter_tests => %w[tests-with-10.json tests-without-10.json]

file 'tests-with-10.json' => 'tests-pruned.json' do |t|
  system "ruby -I. filter-tests.rb -w S.10 #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10.json' => 'tests-pruned.json' do |t|
  system "ruby -I. filter-tests.rb -x S.10 #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate unoptimized test plans

task :unoptimized_test_plans => %w[tests-unoptimized.json tests-with-10-unoptimized.json tests-without-10-unoptimized.json]

file 'tests-unoptimized.json' => %w[tests-pruned.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-unoptimized.json' => %w[tests-with-10.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-unoptimized.json' => %w[tests-without-10.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plans

task :optimized_test_plans => %w[tests-optimized.json tests-with-10-optimized.json tests-without-10-optimized.json]

file 'tests-optimized.json' => %w[tests-pruned.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-optimized.json' => %w[tests-with-10.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-optimized.json' => %w[tests-without-10.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate unoptimized test plan visualizations

task :unoptimized_visualizations => %w[tests-unoptimized-vis.txt tests-with-10-unoptimized-vis.txt tests-without-10-unoptimized-vis.txt]

file 'tests-unoptimized-vis.txt' => %w[tests-unoptimized.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. visualize-plan.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-unoptimized-vis.txt' => %w[tests-with-10-unoptimized.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. visualize-plan.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-unoptimized-vis.txt' => %w[tests-without-10-unoptimized.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. visualize-plan.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plan visualizations

task :optimized_visualizations => %w[tests-optimized-vis.txt tests-with-10-optimized-vis.txt tests-without-10-optimized-vis.txt]

file 'tests-optimized-vis.txt' => %w[tests-optimized.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. visualize-plan.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-optimized-vis.txt' => %w[tests-with-10-optimized.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. visualize-plan.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-optimized-vis.txt' => %w[tests-without-10-optimized.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. visualize-plan.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

task :test_docs => %w[tests-unoptimized.html tests-optimized.html]

# Generate unoptimized test document

file 'tests-unoptimized.adoc' => %w[tests-unoptimized.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. generate-testplan.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-unoptimized.html' => 'tests-unoptimized.adoc' do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plan documents

file 'tests-optimized.adoc' => %w[tests-optimized.json costs.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. generate-testplan.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-optimized.html' => 'tests-optimized.adoc' do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate GanttProject files

task :schedules => %w[tests-unoptimized-schedule.xml tests-optimized-schedule.xml]

file 'tests-unoptimized-schedule.xml' => %w[costs.json tests-unoptimized.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. generate-gantt-project.rb --cost-map costs.json --template GanttProject.xml #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-optimized-schedule.xml' => %w[costs.json tests-optimized.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. generate-gantt-project.rb --cost-map costs.json --template GanttProject.xml #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate progress plot

task :progress_plot => 'test-campaign-progress.png'

file 'test-campaign-progress.png' => %w[tests-unoptimized-schedule.gan tests-optimized-schedule.gan] do |t|
  system "Rscript plot-progress.R #{t.prerequisites.join(' ')} #{t.name}"
end

# Convenience tasks for proxies.

def reproxy(proxy_file)
  FileUtils.rm_f(%w[proxy-map.json])
  FileUtils.ln_s(proxy_file, 'proxy-map.json')
  Rake::Task[:reproxy].invoke
end

task :proxy_none do
  reproxy('proxy-map-none.json')
end

task :proxy_simple do
  reproxy('proxy-map-simple.json')
end

# Convenience tasks for sufficiency.

def reprune(sufficient_file)
  FileUtils.rm_f(%w[sufficient.json])
  FileUtils.ln_s(sufficient_file, 'sufficient.json')
  Rake::Task[:reprune].invoke
end

task :sufficient_none do
  reprune('sufficient-none.json')
end

task :sufficient_least do
  reprune('sufficient-least.json')
end

task :sufficient_least_1 do
  reprune('sufficient-least-1.json')
end

task :sufficient_most do
  reprune('sufficient-most.json')
end

task :sufficient_most_1 do
  reprune('sufficient-most-1.json')
end

task :sufficient_random do
  reprune('sufficient-random.json')
end
