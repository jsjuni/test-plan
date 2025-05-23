task :default => %w[
  costs.json
  tests-optimized-vis.txt
  tests-optimized.html
  tests-optimized-schedule.xml
  tests-unoptimized-vis.txt
  tests-unoptimized.html
  tests-unoptimized-schedule.xml
  tests-with-10-optimized-vis.txt
  tests-with-10-optimized.html
  tests-with-10-unoptimized-vis.txt
  tests-with-10-unoptimized.html
  tests-without-10-optimized-vis.txt
  tests-without-10-optimized.html
  tests-without-10-unoptimized-vis.txt
  tests-without-10-unoptimized.html
]

# Generate requirements

file 'requirements.json' do |t|
  system "ruby -I. generate-requirements.rb > #{t.name}"
end

# Generate scaled cost map

file 'costs.json' => 'requirements.json' do |t|
  system "ruby -I. generate-costs.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate raw tests

file 'tests-raw.json' => %w[requirements.json] do |t|
  system "ruby -I. generate-tests.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

# Filter test subsets

file 'tests-with-10.json' => 'tests-raw.json' do |t|
  system "ruby -I. filter-tests.rb -w 10 #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10.json' => 'tests-raw.json' do |t|
  system "ruby -I. filter-tests.rb -x 10 #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate initial unoptimized test plans

file 'tests-unoptimized.json' => %w[tests-raw.json] do |t|
  system "ruby -I. optimize-test-order.rb --cost-map costs.json --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-unoptimized.json' => %w[tests-with-10.json] do |t|
  system "ruby -I. optimize-test-order.rb --cost-map costs.json --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-unoptimized.json' => %w[tests-without-10.json] do |t|
  system "ruby -I. optimize-test-order.rb --cost-map costs.json --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plans

file 'tests-optimized.json' => %w[tests-raw.json] do |t|
  system "ruby -I. optimize-test-order.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-optimized.json' => %w[tests-with-10.json] do |t|
  system "ruby -I. optimize-test-order.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-optimized.json' => %w[tests-without-10.json] do |t|
  system "ruby -I. optimize-test-order.rb --cost-map costs.json #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate unoptimized test plan visualizations

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

file 'tests-optimized-vis.txt' => 'tests-optimized.json' do |t|
  system "ruby -I. visualize-plan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-optimized-vis.txt' => 'tests-with-10-optimized.json' do |t|
  system "ruby -I. visualize-plan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-optimized-vis.txt' => 'tests-without-10-optimized.json' do |t|
  system "ruby -I. visualize-plan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate unoptimized test documents

file 'tests-unoptimized.adoc' => 'tests-unoptimized.json' do |t|
  system "ruby -I. generate-testplan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-unoptimized.html' => 'tests-unoptimized.adoc' do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-unoptimized.adoc' => 'tests-with-10-unoptimized.json' do |t|
  system "ruby -I. generate-testplan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-unoptimized.html' => 'tests-with-10-unoptimized.adoc' do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-unoptimized.adoc' => 'tests-without-10-unoptimized.json' do |t|
  system "ruby -I. generate-testplan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-unoptimized.html' => 'tests-without-10-unoptimized.adoc' do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plan documents

file 'tests-optimized.adoc' => 'tests-optimized.json' do |t|
  system "ruby -I. generate-testplan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-optimized.html' => 'tests-optimized.adoc' do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-optimized.adoc' => 'tests-with-10-optimized.json' do |t|
  system "ruby -I. generate-testplan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-with-10-optimized.html' => 'tests-with-10-optimized.adoc' do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-optimized.adoc' => 'tests-without-10-optimized.json' do |t|
  system "ruby -I. generate-testplan.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-without-10-optimized.html' => 'tests-without-10-optimized.adoc' do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate GanttProject files

file 'tests-unoptimized-schedule.xml' => 'tests-unoptimized.json' do |t|
  system "ruby -I. generate-gantt-project.rb --template GanttProject.xml #{t.prerequisites.join(' ')} > #{t.name}"
end

file 'tests-optimized-schedule.xml' => 'tests-optimized.json' do |t|
  system "ruby -I. generate-gantt-project.rb --template GanttProject.xml #{t.prerequisites.join(' ')} > #{t.name}"
end
