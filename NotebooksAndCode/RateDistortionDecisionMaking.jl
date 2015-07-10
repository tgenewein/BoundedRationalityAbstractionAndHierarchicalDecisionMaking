module RateDistortionDecisionMaking

#using #dependencies

using DataFrames, Color, Gadfly, 
      Distances.kl_divergence,
      Distributions

export boltzmanndist, BAiterations, setuputilityarrays,
       mutualinformation, expectedutility, entropybits, kl_divergence_bits,
       RDobjective, analyzeBAsolution, performancemeasures2DataFrame,
       boltzmannresult2DataFrame, BAtheme, 
       BAmarginal2DataFrame, BAconditional2DataFrame, BAresult2DataFrame,
       visualizeBAmarginal, visualizeBAconditional, visualizeBAsolution, visualizeMatrix,
       plotperformancemeasures, BAdiscretecolorscale



#include helper functions for mutual information, expected utiliy
include("InformationTheoryFunctions.jl")

#include BlahutArimoto iterations
include("BlahutArimoto.jl")

#include helper functions to aggregate results (as vectors/matrices) into DataFrames
include("ConversionFunctions.jl")

#include helper functions for visualization
include("VisualizationFunctions.jl")




#TODO: document functions (in markdown? look up how to do this properly - Julia 0.4 has @doc macro)

#TODO: write some tests (especially in case future releases break something)

#TODO: adopt src/ test/ structure


end