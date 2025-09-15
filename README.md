# test-plan
Experiments with optimizing test campaign schedules.

## Building

Executing the command `rake` builds test plan documents and predecessor products in folders `build`, `build_unpruned`, and `build_pruned` (see Sufficiency Assertions below). Complete build specifications are in `Rakefile`.

### Proxies for Applicability Situations

Ideally, the test configurations that serve as proxies for applicability situations would be carefully asserted for each requirement. For the purpose of demonstrating the workflow, there are two built-in proxy maps (in `resources`) that provide proxies as follows:

|target|strategy|
|------|--------|
| `proxy_map_none` | test configurations identical to applicability situations |
| `proxy_map_simple` | {`PS.1`} proxy for {`S.16`}, {`PS.2`} proxy for {`S.5`, `S.14`}, {`PS.3`, `PS.4`} proxy for {`S.4`, `S.19`}

The default is `proxy_map_simple`. It can be changed by modifying the variable `proxy_map_json` in `Rakefile`.

### Sufficiency Assertions

For the purpose of sufficiency assertions, assume that the configurations for a given requirement are placed in a directed graph whose edges represent subset relations. That is, if _C<sub>1</sub>_ is a subset of _C<sub>2</sub>_, then there is an edge from _C<sub>1</sub>_ to _C<sub>2</sub>_, and we say _C<sub>1</sub>_ is _less restrictive than_ _C<sub>2</sub>_. The _least restrictive_ configurations are those whose in degree in the graph is 0; the _most restrictive_ configurations are those whose out degree is 0.

|target|strategy|
|------|--------|
| `sufficient_none` | all configurations are necessary |
| `sufficient_least` | all least restrictive configurations are necessary and suffice |
| `sufficient_least_1` | one least restrictive configuration is necessary and suffices |
| `sufficient_most` | all most restrictive configurations are necessary and suffice |
| `sufficient_most_1` | one least restrictive configuration is necessary and suffices |
| `sufficient_random` | random choice of `sufficient_least` or `sufficient_most` for each requirement |
| `sufficient_random_1` | one congfiguration randomly chosen from `sufficient_random` for each requirement |

The default is `sufficient_random_1`. It can be changed by modifying the variable `sufficient_json` in `Rakefile`.

The `Rakefile` executes the complete workflow for both unpruned (in `build/unpruned`, without sufficiency assertions) and pruned (in `build/pruned`, with sufficiency assertions) configurations, for comparison purposes. 

### Optimization Strategy

By default, the test plan optimization strategy uses a Ruby implementation of the [2-opt heuristic](https://en.wikipedia.org/wiki/2-opt). 2-opt is a polynomial time algorithm that appears to yield satisfactory results in many cases.

If the [Concorde TSP Solver](https://www.math.uwaterloo.ca/tsp/concorde.html) is availble, it can be invoked with a Ruby wrapper found [here](https://github.com/jsjuni/ruby-concorde). The `Rakefile` detects the presence of the wrapper files in `lib` and switches automatically.
