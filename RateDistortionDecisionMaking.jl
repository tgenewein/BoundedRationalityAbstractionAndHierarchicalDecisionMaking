module RateDistortionDecisionMaking

#using #dependencies

using DataFrames, Color, Gadfly, 
      Distances.kl_divergence,
      Distributions

export boltzmanndist, BAiterations, setuputilityarrays,
       mutualinformation, expectedutility, entropybits,
       RDobjective, analyzeBAsolution, performancemeasures2DataFrame,
       boltzmannresult2DataFrame, BAtheme, 
       BAmarginal2DataFrame, BAconditional2DataFrame, BAresult2DataFrame,
       visualizeBAmarginal, visualizeBAconditional, visualizeBAsolution,
       plotperformancemeasures, BAdiscretecolorscale



#include helper functions for mutual information, expected utiliy
include("InformationTheoryFunctions.jl")

#include BlahutArimoto iterations
include("BlahutArimoto.jl")

#include helper functions for visualization
include("VisualizationFunctions.jl")



#TODO: perhaps don't expose entropy() (so other code using the method
#remains unaffected)? Maybe insted provide fcn called bitentropy or sth. like that? 


#TODO: also use 'a' and 'o' in InformationTheoryFunctions.jl

#TODO: document functions (in markdown? look up how to do this properly)

#TODO: write some tests (especially in case future releases break something)

#TODO: adopt src/ test/ structure

#TODO: perhaps create a seperate julia file for the conversion functions to DataFrames?

end