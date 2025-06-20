task :default => %w[
  configurations_graph
  unoptimized_visualizations
  optimized_visualizations
  test_docs
  schedules
]

# Generate requirements

task :requirements => 'requirements.json'

file 'requirements.json' do |t|
  system "ruby -I. generate-requirements.rb > #{t.name}"
end

# Generate scaled cost map

task :costs => 'costs.json'

file 'costs.json' => 'requirements.json' do |t|
  system "ruby -I. generate-costs.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate raw tests

task :raw_tests => 'tests-raw.json'

file 'tests-raw.json' => %w[requirements.json] do |t|
  system "ruby -I. generate-tests.rb --graph configurations-graph.json" +
         " --summary requirements-summary.json" +
         " #{t.prerequisites.join(' ')} > #{t.name}"
end

# Visualize configurations graph

task :configurations_graph => 'configurations-graph.svg'

file 'configurations-graph.json' => %w[tests-raw.json]

file 'configurations-graph.dot' => %w[configurations-graph.json] do |t|
  system "ruby graph-to-dot.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'configurations-graph.svg' => %w[configurations-graph.dot] do |t|
  system "dot -Tsvg #{t.prerequisites.join(' ')} > #{t.name}"
end

# Filter test subsets

task :filter_tests => %w[tests-with-10.json tests-without-10.json]

file 'tests-with-10.json' => 'tests-raw.json' do |t|
  system "ruby -I. filter-tests.rb -w S.10 #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10.json' => 'tests-raw.json' do |t|
  system "ruby -I. filter-tests.rb -x S.10 #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate unoptimized test plans

task :unoptimized_test_plans => %w[tests-unoptimized.json tests-with-10-unoptimized.json tests-without-10-unoptimized.json]

file 'tests-unoptimized.json' => %w[costs.json tests-raw.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-unoptimized.json' => %w[tests-with-10.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-unoptimized.json' => %w[tests-without-10.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plans

task :optimized_test_plans => %w[tests-optimized.json tests-with-10-optimized.json tests-without-10-optimized.json]

file 'tests-optimized.json' => %w[tests-raw.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-optimized.json' => %w[tests-with-10.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-optimized.json' => %w[tests-without-10.json] do |t|
  t.prerequisites.delete('costs.json')
  system "ruby -I. optimize-test-order.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate unoptimized test plan visualizations

task :unoptimized_visualizations => %w[tests-unoptimized-vis.txt tests-with-10-unoptimized-vis.txt tests-without-10-unoptimized-vis.txt]

file 'tests-unoptimized-vis.txt' => 'tests-unoptimized.json' do |t|
  system "ruby -I. visualize-plan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-unoptimized-vis.txt' => 'tests-with-10-unoptimized.json' do |t|
  system "ruby -I. visualize-plan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-unoptimized-vis.txt' => 'tests-without-10-unoptimized.json' do |t|
  system "ruby -I. visualize-plan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plan visualizations

task :optimized_visualizations => %w[tests-optimized-vis.txt tests-with-10-optimized-vis.txt tests-without-10-optimized-vis.txt]

file 'tests-optimized-vis.txt' => 'tests-optimized.json' do |t|
  system "ruby -I. visualize-plan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-optimized-vis.txt' => 'tests-with-10-optimized.json' do |t|
  system "ruby -I. visualize-plan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-optimized-vis.txt' => 'tests-without-10-optimized.json' do |t|
  system "ruby -I. visualize-plan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

task :test_docs => %w[tests-unoptimized.html tests-optimized.html]

# Generate unoptimized test document

file 'tests-unoptimized.adoc' => 'tests-unoptimized.json' do |t|
  system "ruby -I. generate-testplan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-unoptimized.html' => 'tests-unoptimized.adoc' do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plan documents

file 'tests-optimized.adoc' => 'tests-optimized.json' do |t|
  system "ruby -I. generate-testplan.rb #{t.prerequisites.join(' ')} > #{t.name}"
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