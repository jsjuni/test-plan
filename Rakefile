require 'fileutils'

BIN_DIR = 'bin'
BUILD_DIR = 'build'
BUILD_UNPRUNED_DIR = 'build_unpruned'
BUILD_PRUNED_DIR = 'build_pruned'
LIB_DIR = 'lib'
RESOURCES_DIR = 'resources'

task :default => %w[
  configurations_graph
  unoptimized_scn_visualizations
  optimized_scn_visualizations
  unoptimized_obs_visualizations
  optimized_obs_visualizations
  test_docs
  schedules
]

task :build_dir => BUILD_DIR

file BUILD_DIR do
  Dir.mkdir(BUILD_DIR) unless Dir.exist?(BUILD_DIR)
end

file BUILD_UNPRUNED_DIR do
  Dir.mkdir(BUILD_UNPRUNED_DIR) unless Dir.exist?(BUILD_UNPRUNED_DIR)
end

file BUILD_PRUNED_DIR do
  Dir.mkdir(BUILD_PRUNED_DIR) unless Dir.exist?(BUILD_PRUNED_DIR)
end

task :clean do
  FileUtils.rm_rf(BUILD_DIR)
  FileUtils.rm_rf(BUILD_UNPRUNED_DIR)
  FileUtils.rm_rf(BUILD_PRUNED_DIR)
  Rake::Task[BUILD_DIR].invoke
  Rake::Task[BUILD_UNPRUNED_DIR].invoke
  Rake::Task[BUILD_PRUNED_DIR].invoke
end

# Generate quantities

quantities_json = "#{RESOURCES_DIR}/quantities.json"
task :quantities => quantities_json

file quantities_json do |t|
  system "ruby #{BIN_DIR}/generate-quantities.rb > #{t.name}"
end

# Generate scenarios

scenarios_json = "#{RESOURCES_DIR}/scenarios.json"
task :scenarios => scenarios_json

file scenarios_json do |t|
  system "ruby #{BIN_DIR}/generate-scenarios.rb > #{t.name}"
end

# Generate requirements

requirements_json = "#{RESOURCES_DIR}/requirements.json"
task :requirements => requirements_json

file requirements_json => [quantities_json, scenarios_json] do |t|
  t.prerequisites.delete(quantities_json)
  t.prerequisites.delete(scenarios_json)
  system "ruby -Ilib #{BIN_DIR}/generate-requirements.rb --number 200 --quantities #{quantities_json} " +
         "--scenarios #{scenarios_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Substitute scenario proxies.

requirements_proxied_json = "#{BUILD_DIR}/requirements-proxied.json"
proxy_map_json = "#{RESOURCES_DIR}/proxy-map-simple.json"
task :substitute_proxies => requirements_proxied_json

file requirements_proxied_json => [requirements_json, proxy_map_json] do |t|
  t.prerequisites.delete(proxy_map_json)
  system "ruby #{BIN_DIR}/substitute-proxies.rb --proxy-map #{proxy_map_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate scaled cost map

costs_json = "#{BUILD_DIR}/costs.json"
task :costs => costs_json

file costs_json => [quantities_json, scenarios_json]  do |t|
  t.prerequisites.delete(quantities_json)
  t.prerequisites.delete(scenarios_json)
  system "ruby -Ilib #{BIN_DIR}/generate-costs.rb --quantities #{quantities_json} --scenarios #{scenarios_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate tests

tests_json = "#{BUILD_DIR}/tests.json"
task :tests => tests_json

configurations_graph_json = "#{BUILD_DIR}/configurations.json"
file configurations_graph_json => requirements_proxied_json

requirements_summary_json = "#{BUILD_DIR}/requirements-summary.json"
file requirements_summary_json => tests_json

file tests_json => [requirements_proxied_json] do |t|
  system "ruby -Ilib #{BIN_DIR}/generate-tests.rb --graph #{configurations_graph_json}" +
         " --summary #{requirements_summary_json}" +
         " #{t.prerequisites.join(' ')} > #{t.name}"
end

# Visualize configurations graph

configurations_graph_dot = "#{BUILD_DIR}/configurations.dot"

file configurations_graph_dot => [configurations_graph_json] do |t|
  system "ruby #{BIN_DIR}/graph-to-dot.rb #{t.prerequisites.join(' ')} > #{t.name}"
end

configurations_graph_svg = "#{BUILD_DIR}/configurations.svg"
task :configurations_graph => configurations_graph_svg

file configurations_graph_svg => [configurations_graph_dot] do |t|
  system "dot -Tsvg #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate (random) sufficiency assertions.

sufficient_none_json = "#{BUILD_PRUNED_DIR}/sufficient-none.json"
sufficient_least_json = "#{BUILD_PRUNED_DIR}/sufficient-least.json"
sufficient_least_1_json = "#{BUILD_PRUNED_DIR}/sufficient-least-1.json"
sufficient_most_json = "#{BUILD_PRUNED_DIR}/sufficient-most.json"
sufficient_most_1_json = "#{BUILD_PRUNED_DIR}/sufficient-most-1.json"
sufficient_random_json = "#{BUILD_PRUNED_DIR}/sufficient-random.json"
sufficient_random_1_json = "#{BUILD_PRUNED_DIR}/sufficient-random-1.json"

task :sufficient => [sufficient_least_json, sufficient_least_1_json, sufficient_most_json, sufficient_most_1_json,
                     sufficient_random_json, sufficient_random_1_json, sufficient_none_json]

file sufficient_least_json => [requirements_summary_json] do |t|
  system "ruby #{BIN_DIR}/generate-sufficiency.rb --p-least 1.0 --seed 0 #{t.prerequisites.join(' ')} > #{t.name}"
end

file sufficient_least_1_json => [requirements_summary_json] do |t|
  system "ruby #{BIN_DIR}/generate-sufficiency.rb --p-least 1.0 --max 1 --seed 0 #{t.prerequisites.join(' ')} > #{t.name}"
end

file sufficient_most_json => [requirements_summary_json] do |t|
  system "ruby #{BIN_DIR}/generate-sufficiency.rb --p-least 0.0 --seed 0 #{t.prerequisites.join(' ')} > #{t.name}"
end

file sufficient_most_1_json => [requirements_summary_json] do |t|
  system "ruby #{BIN_DIR}/generate-sufficiency.rb --p-least 0.0 --max 1 --seed 0 #{t.prerequisites.join(' ')} > #{t.name}"
end

file sufficient_random_json => [requirements_summary_json] do |t|
  system "ruby #{BIN_DIR}/generate-sufficiency.rb --p-least 0.5 --seed 0 #{t.prerequisites.join(' ')} > #{t.name}"
end

file sufficient_random_1_json => [requirements_summary_json] do |t|
  system "ruby #{BIN_DIR}/generate-sufficiency.rb --p-least 0.5 --max 1 --seed 0 #{t.prerequisites.join(' ')} > #{t.name}"
end

file sufficient_none_json => [requirements_summary_json] do |t|
  system "cat #{t.prerequisites.join(' ')} > #{t.name}"
end

# Prune tests using sufficiency assertions

tests_pruned_json = "#{BUILD_PRUNED_DIR}/tests-pruned.json"
sufficient_json = sufficient_least_1_json
task :pruned_tests => [tests_pruned_json]

file tests_pruned_json => [tests_json, sufficient_json] do |t|
  t.prerequisites.delete(sufficient_json)
  system "ruby #{BIN_DIR}/prune-tests.rb --sufficiency #{sufficient_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Filter test subsets

task :filter_tests => [:filter_unpruned_tests, :filter_pruned_tests]

tests_unpruned_with_10_json = "#{BUILD_UNPRUNED_DIR}/tests-with-10.json"
tests_unpruned_without_10_json = "#{BUILD_UNPRUNED_DIR}/tests-without-10.json"
task :filter_unpruned_tests => [tests_unpruned_with_10_json, tests_unpruned_without_10_json]

file tests_unpruned_with_10_json => [tests_json] do |t|
  system "ruby -Ilib #{BIN_DIR}/filter-tests.rb -w S.10 #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_without_10_json => [tests_json] do |t|
  system "ruby -Ilib #{BIN_DIR}/filter-tests.rb -x S.10 #{t.prerequisites.join(' ')} > #{t.name}"
end

tests_pruned_with_10_json = "#{BUILD_PRUNED_DIR}/tests-with-10.json"
tests_pruned_without_10_json = "#{BUILD_PRUNED_DIR}/tests-without-10.json"
task :filter_pruned_tests => [tests_pruned_with_10_json, tests_pruned_without_10_json]

file tests_pruned_with_10_json => [tests_pruned_json] do |t|
  system "ruby -Ilib #{BIN_DIR}/filter-tests.rb -w S.10 #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_without_10_json => [tests_pruned_json] do |t|
  system "ruby -Ilib #{BIN_DIR}/filter-tests.rb -x S.10 #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate unoptimized test plans

task :unoptimized_test_plans => [:unpruned_unoptimized_test_plans, :pruned_unoptimized_test_plans]

tests_unpruned_json = tests_json
tests_unpruned_unoptimized_json = "#{BUILD_UNPRUNED_DIR}/tests-unoptimized.json"
tests_unpruned_with_10_unoptimized_json = "#{BUILD_UNPRUNED_DIR}/tests-with-10-unoptimized.json"
tests_unpruned_without_10_unoptimized_json = "#{BUILD_UNPRUNED_DIR}/tests-without-10-unoptimized.json"
task :unpruned_unoptimized_test_plans => [tests_unpruned_unoptimized_json, tests_unpruned_with_10_unoptimized_json, tests_unpruned_without_10_unoptimized_json]

file tests_unpruned_unoptimized_json => [tests_unpruned_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_with_10_unoptimized_json => [tests_unpruned_with_10_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_without_10_unoptimized_json => [tests_unpruned_without_10_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

tests_pruned_unoptimized_json = "#{BUILD_PRUNED_DIR}/tests-unoptimized.json"
tests_pruned_with_10_unoptimized_json = "#{BUILD_PRUNED_DIR}/tests-with-10-unoptimized.json"
tests_pruned_without_10_unoptimized_json = "#{BUILD_PRUNED_DIR}/tests-without-10-unoptimized.json"
task :pruned_unoptimized_test_plans => [tests_pruned_unoptimized_json, tests_pruned_with_10_unoptimized_json, tests_pruned_without_10_unoptimized_json]

file tests_pruned_unoptimized_json => [tests_pruned_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_with_10_unoptimized_json => [tests_pruned_with_10_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_without_10_unoptimized_json => [tests_pruned_without_10_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --no-optimize #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plans

task :optimized_test_plans => [:unpruned_unoptimized_test_plans, :pruned_unoptimized_test_plans]

tests_unpruned_optimized_json = "#{BUILD_UNPRUNED_DIR}/tests-optimized.json"
tests_unpruned_with_10_optimized_json = "#{BUILD_UNPRUNED_DIR}/tests-with-10-optimized.json"
tests_unpruned_without_10_optimized_json = "#{BUILD_UNPRUNED_DIR}/tests-without-10-optimized.json"
task :unpruned_optimized_test_plans => [tests_unpruned_optimized_json, tests_unpruned_with_10_optimized_json, tests_unpruned_without_10_optimized_json]

file tests_unpruned_optimized_json => [tests_unpruned_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --concorde #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_with_10_optimized_json => [tests_unpruned_with_10_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --concorde #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_without_10_optimized_json => [tests_unpruned_without_10_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --concorde #{t.prerequisites.join(' ')} > #{t.name}"
end

tests_pruned_optimized_json = "#{BUILD_PRUNED_DIR}/tests-optimized.json"
tests_pruned_with_10_optimized_json = "#{BUILD_PRUNED_DIR}/tests-with-10-optimized.json"
tests_pruned_without_10_optimized_json = "#{BUILD_PRUNED_DIR}/tests-without-10-optimized.json"
task :pruned_optimized_test_plans => [tests_pruned_optimized_json, tests_pruned_with_10_optimized_json, tests_pruned_without_10_optimized_json]

file tests_pruned_optimized_json => [tests_pruned_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --concorde #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_with_10_optimized_json => [tests_pruned_with_10_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --concorde #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_without_10_optimized_json => [tests_pruned_without_10_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/optimize-test-order.rb --cost-map #{costs_json} --concorde #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate unoptimized test plan scenario visualizations

task :unoptimized_scn_visualizations => [:unpruned_unoptimized_scn_visualizations, :pruned_unoptimized_scn_visualizations]

tests_unpruned_unoptimized_scn_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-unoptimized-scn-vis.txt"
tests_unpruned_with_10_unoptimized_scn_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-with-10-unoptimized-scn-vis.txt"
tests_unpruned_without_10_unoptimized_scn_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-without-10-unoptimized-scn-vis.txt"
task :unpruned_unoptimized_scn_visualizations => [tests_unpruned_unoptimized_scn_vis_txt, tests_unpruned_with_10_unoptimized_scn_vis_txt, tests_unpruned_without_10_unoptimized_scn_vis_txt]

file tests_unpruned_unoptimized_scn_vis_txt => [tests_unpruned_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_with_10_unoptimized_scn_vis_txt => [tests_unpruned_with_10_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_without_10_unoptimized_scn_vis_txt => [tests_unpruned_without_10_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

tests_pruned_unoptimized_scn_vis_txt = "#{BUILD_PRUNED_DIR}/tests-unoptimized-scn-vis.txt"
tests_pruned_with_10_unoptimized_scn_vis_txt = "#{BUILD_PRUNED_DIR}/tests-with-10-unoptimized-scn-vis.txt"
tests_pruned_without_10_unoptimized_scn_vis_txt = "#{BUILD_PRUNED_DIR}/tests-without-10-unoptimized-scn-vis.txt"
task :pruned_unoptimized_scn_visualizations => [tests_pruned_unoptimized_scn_vis_txt, tests_pruned_with_10_unoptimized_scn_vis_txt, tests_pruned_without_10_unoptimized_scn_vis_txt]

file tests_pruned_unoptimized_scn_vis_txt => [tests_pruned_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_with_10_unoptimized_scn_vis_txt => [tests_pruned_with_10_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_without_10_unoptimized_scn_vis_txt => [tests_pruned_without_10_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plan scenario visualizations

task :optimized_scn_visualizations => [:unpruned_optimized_scn_visualizations, :pruned_optimized_scn_visualizations]

tests_unpruned_optimized_scn_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-optimized-scn-vis.txt"
tests_unpruned_with_10_optimized_scn_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-with-10-optimized-scn-vis.txt"
tests_unpruned_without_10_optimized_scn_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-without-10-optimized-scn-vis.txt"
task :unpruned_optimized_scn_visualizations => [tests_unpruned_optimized_scn_vis_txt, tests_unpruned_with_10_optimized_scn_vis_txt, tests_unpruned_without_10_optimized_scn_vis_txt]

file tests_unpruned_optimized_scn_vis_txt => [tests_unpruned_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_with_10_optimized_scn_vis_txt => [tests_unpruned_with_10_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_without_10_optimized_scn_vis_txt => [tests_unpruned_without_10_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

tests_pruned_optimized_scn_vis_txt = "#{BUILD_PRUNED_DIR}/tests-optimized-scn-vis.txt"
tests_pruned_with_10_optimized_scn_vis_txt = "#{BUILD_PRUNED_DIR}/tests-with-10-optimized-scn-vis.txt"
tests_pruned_without_10_optimized_scn_vis_txt = "#{BUILD_PRUNED_DIR}/tests-without-10-optimized-scn-vis.txt"
task :pruned_optimized_scn_visualizations => [tests_pruned_optimized_scn_vis_txt, tests_pruned_with_10_optimized_scn_vis_txt, tests_pruned_without_10_optimized_scn_vis_txt]

file tests_pruned_optimized_scn_vis_txt => [tests_pruned_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_with_10_optimized_scn_vis_txt => [tests_pruned_with_10_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_without_10_optimized_scn_vis_txt => [tests_pruned_without_10_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate unoptimized test plan observation visualizations

task :unoptimized_obs_visualizations => [:unpruned_unoptimized_obs_visualizations, :unpruned_optimized_obs_visualizations]

tests_unpruned_unoptimized_obs_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-unoptimized-obs-vis.txt"
tests_unpruned_with_10_unoptimized_obs_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-with-10-unoptimized-obs-vis.txt"
tests_unpruned_without_10_unoptimized_obs_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-without-10-unoptimized-obs-vis.txt"
task :unpruned_unoptimized_obs_visualizations => [tests_unpruned_unoptimized_obs_vis_txt, tests_unpruned_with_10_unoptimized_obs_vis_txt, tests_unpruned_without_10_unoptimized_obs_vis_txt]

file tests_unpruned_unoptimized_obs_vis_txt => [tests_unpruned_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_with_10_unoptimized_obs_vis_txt => [tests_unpruned_with_10_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_without_10_unoptimized_obs_vis_txt => [tests_unpruned_without_10_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

tests_pruned_unoptimized_obs_vis_txt = "#{BUILD_PRUNED_DIR}/tests-unoptimized-obs-vis.txt"
tests_pruned_with_10_unoptimized_obs_vis_txt = "#{BUILD_PRUNED_DIR}/tests-with-10-unoptimized-obs-vis.txt"
tests_pruned_without_10_unoptimized_obs_vis_txt = "#{BUILD_PRUNED_DIR}/tests-without-10-unoptimized-obs-vis.txt"
task :pruned_unoptimized_obs_visualizations => [tests_pruned_unoptimized_obs_vis_txt, tests_pruned_with_10_unoptimized_obs_vis_txt, tests_pruned_without_10_unoptimized_obs_vis_txt]

file tests_pruned_unoptimized_obs_vis_txt => [tests_pruned_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_with_10_unoptimized_obs_vis_txt => [tests_pruned_with_10_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_without_10_unoptimized_obs_vis_txt => [tests_pruned_without_10_unoptimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plan observation visualizations

task :optimized_obs_visualizations => [:unpruned_optimized_obs_visualizations, :pruned_optimized_obs_visualizations]

tests_unpruned_optimized_obs_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-optimized-obs-vis.txt"
tests_unpruned_with_10_optimized_obs_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-with-10-optimized-obs-vis.txt"
tests_unpruned_without_10_optimized_obs_vis_txt = "#{BUILD_UNPRUNED_DIR}/tests-without-10-optimized-obs-vis.txt"
task :unpruned_optimized_obs_visualizations => [tests_unpruned_optimized_obs_vis_txt, tests_unpruned_with_10_optimized_obs_vis_txt, tests_unpruned_without_10_optimized_obs_vis_txt]

file tests_unpruned_optimized_obs_vis_txt => [tests_unpruned_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_with_10_optimized_obs_vis_txt => [tests_unpruned_with_10_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_without_10_optimized_obs_vis_txt => [tests_unpruned_without_10_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

tests_pruned_optimized_obs_vis_txt = "#{BUILD_PRUNED_DIR}/tests-optimized-obs-vis.txt"
tests_pruned_with_10_optimized_obs_vis_txt = "#{BUILD_PRUNED_DIR}/tests-with-10-optimized-obs-vis.txt"
tests_pruned_without_10_optimized_obs_vis_txt = "#{BUILD_PRUNED_DIR}/tests-without-10-optimized-obs-vis.txt"
task :pruned_optimized_obs_visualizations => [tests_pruned_optimized_obs_vis_txt, tests_pruned_with_10_optimized_obs_vis_txt, tests_pruned_without_10_optimized_obs_vis_txt]

file tests_pruned_optimized_obs_vis_txt => [tests_pruned_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_with_10_optimized_obs_vis_txt => [tests_pruned_with_10_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_without_10_optimized_obs_vis_txt => [tests_pruned_without_10_optimized_json, costs_json] do |t|
  t.prerequisites.delete(costs_json)
  system "ruby -Ilib #{BIN_DIR}/visualize-plan.rb --observations --cost-map #{costs_json} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate heat maps for test plan documents

task :heat_maps => [:unpruned_heat_maps, :pruned_heat_maps]

tests_unpruned_unoptimized_scn_heat_png = "#{BUILD_UNPRUNED_DIR}/tests-unoptimized-scn-heat.png"
tests_unpruned_unoptimized_obs_heat_png = "#{BUILD_UNPRUNED_DIR}/tests-unoptimized-obs-heat.png"
tests_unpruned_optimized_scn_heat_png = "#{BUILD_UNPRUNED_DIR}/tests-optimized-scn-heat.png"
tests_unpruned_optimized_obs_heat_png = "#{BUILD_UNPRUNED_DIR}/tests-optimized-obs-heat.png"

task :unpruned_heat_maps => [tests_unpruned_unoptimized_scn_heat_png, tests_unpruned_unoptimized_obs_heat_png, tests_unpruned_optimized_scn_heat_png, tests_unpruned_optimized_obs_heat_png]

file tests_unpruned_unoptimized_scn_heat_png => [costs_json, tests_unpruned_unoptimized_json] do |t|
  t.prerequisites.delete(costs_json)
  system "Rscript bin/generate-heat-map.R --configuration #{costs_json} #{t.prerequisites.first} #{t.name}"
end

file tests_unpruned_unoptimized_obs_heat_png => [costs_json, tests_unpruned_unoptimized_json] do |t|
  t.prerequisites.delete(costs_json)
  system "Rscript bin/generate-heat-map.R --observation #{costs_json} #{t.prerequisites.first} #{t.name}"
end

file tests_unpruned_optimized_scn_heat_png => [costs_json, tests_unpruned_optimized_json] do |t|
  t.prerequisites.delete(costs_json)
  system "Rscript bin/generate-heat-map.R --configuration #{costs_json} #{t.prerequisites.first} #{t.name}"
end

file tests_unpruned_optimized_obs_heat_png => [costs_json, tests_unpruned_optimized_json] do |t|
  t.prerequisites.delete(costs_json)
  system "Rscript bin/generate-heat-map.R --observation #{costs_json} #{t.prerequisites.first} #{t.name}"
end

tests_pruned_unoptimized_scn_heat_png = "#{BUILD_PRUNED_DIR}/tests-unoptimized-scn-heat.png"
tests_pruned_unoptimized_obs_heat_png = "#{BUILD_PRUNED_DIR}/tests-unoptimized-obs-heat.png"
tests_pruned_optimized_scn_heat_png = "#{BUILD_PRUNED_DIR}/tests-optimized-scn-heat.png"
tests_pruned_optimized_obs_heat_png = "#{BUILD_PRUNED_DIR}/tests-optimized-obs-heat.png"

task :pruned_heat_maps => [tests_pruned_unoptimized_scn_heat_png, tests_pruned_unoptimized_obs_heat_png, tests_pruned_optimized_scn_heat_png, tests_pruned_optimized_obs_heat_png]

file tests_pruned_unoptimized_scn_heat_png => [costs_json, tests_pruned_unoptimized_json] do |t|
  t.prerequisites.delete(costs_json)
  system "Rscript bin/generate-heat-map.R --configuration #{costs_json} #{t.prerequisites.first} #{t.name}"
end

file tests_pruned_unoptimized_obs_heat_png => [costs_json, tests_pruned_unoptimized_json] do |t|
  t.prerequisites.delete(costs_json)
  system "Rscript bin/generate-heat-map.R --observation #{costs_json} #{t.prerequisites.first} #{t.name}"
end

file tests_pruned_optimized_scn_heat_png => [costs_json, tests_pruned_optimized_json] do |t|
  t.prerequisites.delete(costs_json)
  system "Rscript bin/generate-heat-map.R --configuration #{costs_json} #{t.prerequisites.first} #{t.name}"
end

file tests_pruned_optimized_obs_heat_png => [costs_json, tests_pruned_optimized_json] do |t|
  t.prerequisites.delete(costs_json)
  system "Rscript bin/generate-heat-map.R --observation #{costs_json} #{t.prerequisites.first} #{t.name}"
end

# Generate test plan documents

task :test_docs => [:pruned_test_docs, :unpruned_test_docs]

tests_pruned_unoptimized_html = "#{BUILD_PRUNED_DIR}/tests-unoptimized.html"
tests_pruned_optimized_html = "#{BUILD_PRUNED_DIR}/tests-optimized.html"
task :pruned_test_docs => [tests_pruned_unoptimized_html, tests_pruned_optimized_html]

# Generate unoptimized test plan document

tests_pruned_unoptimized_adoc = "#{BUILD_PRUNED_DIR}/tests-unoptimized.adoc"
file tests_pruned_unoptimized_adoc => [tests_pruned_unoptimized_json, costs_json, tests_pruned_unoptimized_scn_heat_png, tests_pruned_unoptimized_obs_heat_png] do |t|
  t.prerequisites.delete(costs_json)
  t.prerequisites.delete(tests_pruned_unoptimized_scn_heat_png)
  t.prerequisites.delete(tests_pruned_unoptimized_obs_heat_png)
  system "ruby -Ilib #{BIN_DIR}/generate-testplan.rb " +
         "--configuration #{tests_pruned_unoptimized_scn_heat_png} --observation #{tests_pruned_unoptimized_obs_heat_png} #{t.prerequisites.join(' ')} > #{t.name}"
end

task :unoptimized_documents => [tests_pruned_unoptimized_html]
file tests_pruned_unoptimized_html => tests_pruned_unoptimized_adoc do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plan document

tests_pruned_optimized_adoc = "#{BUILD_PRUNED_DIR}/tests-optimized.adoc"
file tests_pruned_optimized_adoc => [tests_pruned_optimized_json, costs_json, tests_pruned_optimized_scn_heat_png, tests_pruned_optimized_obs_heat_png] do |t|
  t.prerequisites.delete(costs_json)
  t.prerequisites.delete(tests_pruned_optimized_scn_heat_png)
  t.prerequisites.delete(tests_pruned_optimized_obs_heat_png)
  system "ruby -Ilib #{BIN_DIR}/generate-testplan.rb --optimized " +
         "--configuration #{tests_pruned_optimized_scn_heat_png} --observation #{tests_pruned_optimized_obs_heat_png} #{t.prerequisites.join(' ')} > #{t.name}"
end

task :optimized_documents => [tests_pruned_optimized_html]
file tests_pruned_optimized_html => tests_pruned_optimized_adoc do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

tests_unpruned_unoptimized_html = "#{BUILD_UNPRUNED_DIR}/tests-unoptimized.html"
tests_unpruned_optimized_html = "#{BUILD_UNPRUNED_DIR}/tests-optimized.html"
task :unpruned_test_docs => [tests_unpruned_unoptimized_html, tests_unpruned_optimized_html]

# Generate unoptimized test plan document

tests_unpruned_unoptimized_adoc = "#{BUILD_UNPRUNED_DIR}/tests-unoptimized.adoc"
file tests_unpruned_unoptimized_adoc => [tests_unpruned_unoptimized_json, costs_json, tests_unpruned_unoptimized_scn_heat_png, tests_unpruned_unoptimized_obs_heat_png] do |t|
  t.prerequisites.delete(costs_json)
  t.prerequisites.delete(tests_unpruned_unoptimized_scn_heat_png)
  t.prerequisites.delete(tests_unpruned_unoptimized_obs_heat_png)
  system "ruby -Ilib #{BIN_DIR}/generate-testplan.rb " +
         "--configuration #{tests_unpruned_unoptimized_scn_heat_png} --observation #{tests_unpruned_unoptimized_obs_heat_png} #{t.prerequisites.join(' ')} > #{t.name}"
end

task :unoptimized_documents => [tests_unpruned_unoptimized_html]
file tests_unpruned_unoptimized_html => tests_unpruned_unoptimized_adoc do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate optimized test plan document

tests_unpruned_optimized_adoc = "#{BUILD_UNPRUNED_DIR}/tests-optimized.adoc"
file tests_unpruned_optimized_adoc => [tests_unpruned_optimized_json, costs_json, tests_unpruned_optimized_scn_heat_png, tests_unpruned_optimized_obs_heat_png] do |t|
  t.prerequisites.delete(costs_json)
  t.prerequisites.delete(tests_unpruned_optimized_scn_heat_png)
  t.prerequisites.delete(tests_unpruned_optimized_obs_heat_png)
  system "ruby -Ilib #{BIN_DIR}/generate-testplan.rb --optimized " +
         "--configuration #{tests_unpruned_optimized_scn_heat_png} --observation #{tests_unpruned_optimized_obs_heat_png} #{t.prerequisites.join(' ')} > #{t.name}"
end

task :optimized_documents => [tests_unpruned_optimized_html]
file tests_unpruned_optimized_html => tests_unpruned_optimized_adoc do |t|
  system "asciidoctor -o #{t.name} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate GanttProject files

task :schedules => [:pruned_schedules, :unpruned_schedules]

tests_pruned_unoptimized_schedule_xml = "#{BUILD_PRUNED_DIR}/tests-unoptimized-schedule.xml"
tests_pruned_optimized_schedule_xml = "#{BUILD_PRUNED_DIR}/tests-optimized-schedule.xml"
gantt_project_xml = "#{RESOURCES_DIR}/GanttProject.xml"
task :pruned_schedules => [tests_pruned_unoptimized_schedule_xml, tests_pruned_optimized_schedule_xml]

file tests_pruned_unoptimized_schedule_xml => [tests_pruned_unoptimized_json, costs_json, gantt_project_xml] do |t|
  t.prerequisites.delete(costs_json)
  t.prerequisites.delete(gantt_project_xml)
  system "ruby -Ilib #{BIN_DIR}/generate-gantt-project.rb --cost-map #{costs_json} --template #{gantt_project_xml} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_pruned_optimized_schedule_xml => [tests_pruned_optimized_json, costs_json, gantt_project_xml] do |t|
  t.prerequisites.delete(costs_json)
  t.prerequisites.delete(gantt_project_xml)
  system "ruby -Ilib #{BIN_DIR}/generate-gantt-project.rb --cost-map #{costs_json} --template #{gantt_project_xml} #{t.prerequisites.join(' ')} > #{t.name}"
end

tests_unpruned_unoptimized_schedule_xml = "#{BUILD_UNPRUNED_DIR}/tests-unoptimized-schedule.xml"
tests_unpruned_optimized_schedule_xml = "#{BUILD_UNPRUNED_DIR}/tests-optimized-schedule.xml"
gantt_project_xml = "#{RESOURCES_DIR}/GanttProject.xml"
task :unpruned_schedules => [tests_unpruned_unoptimized_schedule_xml, tests_unpruned_optimized_schedule_xml]

file tests_unpruned_unoptimized_schedule_xml => [tests_unpruned_unoptimized_json, costs_json, gantt_project_xml] do |t|
  t.prerequisites.delete(costs_json)
  t.prerequisites.delete(gantt_project_xml)
  system "ruby -Ilib #{BIN_DIR}/generate-gantt-project.rb --cost-map #{costs_json} --template #{gantt_project_xml} #{t.prerequisites.join(' ')} > #{t.name}"
end

file tests_unpruned_optimized_schedule_xml => [tests_unpruned_optimized_json, costs_json, gantt_project_xml] do |t|
  t.prerequisites.delete(costs_json)
  t.prerequisites.delete(gantt_project_xml)
  system "ruby -Ilib #{BIN_DIR}/generate-gantt-project.rb --cost-map #{costs_json} --template #{gantt_project_xml} #{t.prerequisites.join(' ')} > #{t.name}"
end

# Generate progress plot

tests_pruned_unoptimized_schedule_gan = "#{BUILD_PRUNED_DIR}/tests-unoptimized-schedule.gan"
tests_pruned_optimized_schedule_gan = "#{BUILD_PRUNED_DIR}/tests-optimized-schedule.gan"
test_campaign_progress_png = "#{BUILD_PRUNED_DIR}/test-campaign-progress.png"
task :progress_plot => test_campaign_progress_png

file test_campaign_progress_png => [tests_pruned_unoptimized_schedule_gan, tests_pruned_optimized_schedule_gan] do |t|
  system "Rscript bin/progress.R #{t.prerequisites.join(' ')} #{t.name}"
end
