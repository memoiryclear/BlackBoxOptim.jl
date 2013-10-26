using GlobalOptim
using FactCheck

my_tests = [
  "test_fitness.jl",
  "test_population.jl",
  "problems/test_single_objective.jl",
  "test_differential_evolution.jl"
]

for t in my_tests
  include(t)
end
