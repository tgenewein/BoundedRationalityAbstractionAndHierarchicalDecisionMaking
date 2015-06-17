module RateDistortionDecisionMaking

#using #dependencies

using DataFrames, Color, Gadfly, Distances.kl_divergence, Distributions.Distribution


import Distributions.entropy


export boltzmanndist, BAiterations, setuputilityarrays,
       mutualinformation, expectedutility, entropy,
       boltzmannresult2DataFrame, BATheme, 
       BAmarginal2DataFrame, BAconditional2DataFrame, BAresult2DataFrame,
       visualizeBAmarginal, visualizeBAconditional, visualizeBAsolution


#include BlahutArimoto iterations
include("BlahutArimoto.jl")

#include helper functions for mutual information, expected utiliy
include("InformationTheoryFunctions.jl")

#include helper functions for visualization
include("VisualizationFunctions.jl")



#TODO: perhaps don't expose entropy() (so other code using the method
#remains unaffected)? Maybe insted provide fcn called bitentropy or sth. like that? 


#TODO: also use 'a' and 'o' in InformationTheoryFunctions.jl

#TODO: document functions (in markdown? look up how to do this properly)

#TODO: write some tests (especially in case future releases break something)

#TODO: adopt src/ test/ structure

end