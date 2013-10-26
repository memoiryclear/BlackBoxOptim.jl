using Distributions

type DiffEvoOpt <: PopulationOptimizer
  # A population is a matrix of floats.
  population::Array{Float64, 2}

  # A search space is defined by the min and max values (in tuples) for each
  # of its dimenions. The dimension is the length of an individual, i.e. the
  # number of Float64 values in it.
  search_space::Array{(Float64,Float64),1}

  # Options
  options::Dict{Any,Any}

  # Set of functions that together define a specific DE strategy.
  sample::Function
  mutate::Function
  crossover::Function
  bound::Function
end

# Ask for a new candidate object to be evaluated, and a list of individuals
# it should be ranked with. The individuals are supplied as an array of tuples
# with the individual and its index.
function ask(de::DiffEvoOpt)
  # Sample parents and target
  numparents = de.options["NumParents"]
  indices = de.sample(de, 1 + numparents)
  #print("indices = "); show(indices); println("")
  parent_indices = indices[1:numparents]
  #print("parent_indices = "); show(parent_indices); println("")
  target_index = indices[end]
  #print("target_index = "); show(target_index); println("")
  target = de.population[target_index,:]
  #print("target = "); show(target); println("")

  # DE/rand/1 mutation strategy
  donor = de.mutate(de, parent_indices)
  #print("donor = "); show(donor); println("")

  # Crossover donor and target
  trial = de.crossover(de, target, donor)

  # Bound the trial vector according to search space bounds
  trial = de.bound(trial, target, de.search_space)

  # Return the candidates that should be ranked as tuples including their 
  # population indices.
  return [(trial, target_index), (target, target_index)]
end

function random_sampler(de::DiffEvoOpt, numSamples)
  sample(1:size(de.population,1), numSamples; replace = false)
end

# DE/rand/1 mutation strategy
function de_mutation_rand_1(de::DiffEvoOpt, parentIndices)
  f = de.options["f"]
  p = de.population[parentIndices,:]
  return p[3,:] + (f * (p[1,:] - p[2,:]))
end

# Binomial crossover for DE, i.e. DE/*/*/bin.
function de_crossover_binomial(de::DiffEvoOpt, target, donor)
  trial = copy(target)

  # Always ensure at least one value from donor is copied to trial vector
  jrand = rand(1:length(trial))
  trial[jrand] = donor[jrand]

  # Now crossover randomly for the rest of the indices
  switch = rand(length(trial)) .<= de.options["cr"]
  #print("switch = "); show(switch); println("")
  #print("trial = "); show(trial); println("")
  #print("donor = "); show(donor); println("")
  trial[:,switch] = donor[:,switch]
  #print("trial = "); show(trial); println("")

  return trial
end

# If we come out-of-bounds we randomly sample between the target value
# and the bound.
function rand_bound_from_target!(individual, target, searchSpace)
  for i in 1:length(individual)
    min, max = searchSpace[i]
    #print("min = "); show(min); println("")
    #print("max = "); show(max); println("")
    #print("i = "); show(i); println("")
    #print("ind[i,1] = "); show(individual[i,1]); println("")

    if individual[i] < min
      individual[i] = min + rand() * (target[i] - min)
    elseif individual[i] > max
      individual[i] = target[i] + rand() * (max - target[i])
    end
  end
  individual
end

# Tell the optimizer about the ranking of candidates. Returns the number of
# better candidates that were inserted into the population.
function tell!(de::DiffEvoOpt, 
  # archive::Archive, # Skip for now
  rankedCandidates)
  num_candidates = length(rankedCandidates)
  num_better = 0
  for i in 1:div(num_candidates, 2)
    candidate, index = rankedCandidates[i]
    if candidate != de.population[index, :]
      num_better += 1
      #print("candidate = "); show(candidate); println("")
      #print("index = "); show(index); println("")
      #print("target = "); show(de.population[index,:]); println("")
      old = de.population[index,:]
      de.population[index,:] = candidate
    end
  end
  num_better
end

DE_DefaultOptions = {
  "f" => 0.65,
  "cr" => 0.4,
  "NumParents" => 3,
}

# Now we can create specific DE optimizers that are commonly used in the
# literature.

# The most used DE/rand/1/bin.
function de_rand_1_bin(population, searchSpace, options = DE_DefaultOptions)
  DiffEvoOpt(population, searchSpace, options, 
    random_sampler, 
    de_mutation_rand_1, 
    de_crossover_binomial, 
    rand_bound_from_target!)
end

# The most used DE/rand/1/bin.
function de_rand_1_bin(population, searchSpace, options = DE_DefaultOptions)
  DiffEvoOpt(population, searchSpace, options, 
    random_sampler, 
    de_mutation_rand_1, 
    de_crossover_binomial, 
    rand_bound_from_target!)
end
