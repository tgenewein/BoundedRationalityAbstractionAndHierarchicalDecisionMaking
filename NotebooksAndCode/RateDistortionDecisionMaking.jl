module RateDistortionDecisionMaking

#using #dependencies

using DataFrames, Colors, Gadfly,
      Patchwork,  #there seems to be an issue with Patchwork and firefox right now
      Distances.kl_divergence,
      Distributions,
      Reactive, Interact

export boltzmanndist, BAiterations, setuputilityarrays,
       compute_marginals, marginalizeo, threevarBAiterations,
       mutualinformation, conditional_mutualinformation, expectedutility, entropybits,
       log_bits, kl_divergence_bits,
       RDobjective, ThreeVArRDobjective, analyzeBAsolution, analyze_three_var_BAsolution,
       BAtheme, BAcontinuouscolorscale, BAmatrixvisscale, BAprobabilityvisscale, BAdiscretecolorscale,
       visualizeBAmarginal, visualizeBAconditional, visualizeBAsolution, visualizeMatrix,
       visualizeBA_double_conditional, visualize_three_var_BAsolution,
       plotperformancemeasures, plot_three_var_BA_convergence, plot_three_var_performancemeasures,
       boltzmannresult2DataFrame, BAmarginal2DataFrame, BAconditional2DataFrame,
       BAresult2DataFrame, performancemeasures2DataFrame,
       visualize_three_var_BAsolution, plot_three_var_performancemeasures



#include helper functions for mutual information, expected utiliy
include("InformationTheoryFunctions.jl")

#include BlahutArimoto iterations
include("BlahutArimoto.jl")

#include three-variable iteration schemes
include("ThreeVariableBlahutArimoto.jl")


#include helper functions to aggregate results (as vectors/matrices) into DataFrames
include("ConversionFunctions.jl")

#include helper functions for visualization
include("VisualizationFunctions.jl")


end
