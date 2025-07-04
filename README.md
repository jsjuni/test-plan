# test-plan
Experiments with optimizing test campaign schedules.

## Building

The following steps build unoptimized and optimized test plan documents in the `build` directory: `tests-unoptimized.html` and `tests-optimized.html`.

1. `rake clean`
2. `rake proxy_none`
3. `rake sufficient_none`
4. `rake`

### Proxies for Applicability Situations

Ideally, the test configurations that serve as proxies for applicability situations would be carefully asserted for each requirement. For the purpose of demonstrating the workflow, there are two built-in proxy maps (in `resources`) that provide proxies as follows:

|target|strategy|
|------|--------|
| `proxy_none` | test configurations identical to applicability situations |
| `proxy_simple` | {`PS.1`} proxy for {`S.16`}, {`PS.2`} proxy for {`S.5`, `S.14`}, {`PS.3`, `PS.4`} proxy for {`S.4`, `S.19`}

Switch proxy strategy by `rake`_`proxy_target`_ followed by `rake`.

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
| `sufficient_least_1` | one congfiguration randomly chosen from `sufficient_random` for each requirement |

Switch sufficency strategy by `rake`_`sufficiency_target`_ followed by `rake`.

### Optimization Strategy

By default, the test plan optimization strategy uses the [Concorde TSP Solver](https://www.math.uwaterloo.ca/tsp/concorde.html) running in a Docker container with image [alehkot/concorde-tsp](https://hub.docker.com/r/alehkot/concorde-tsp). Calling this solver requires a Ruby wrapper not included in this repository. To use the built-in 2-opt heuristic, edit `Rakefile` and remove the argument `--concorde` from three locations.

2-opt is very fast and produces a tour approximately 10% longer than Concorde (in limited testing).