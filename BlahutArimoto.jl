module BlahutArimoto

#using #dependencies

using DataFrames, Color, Gadfly, Distances, Distributions.Distribution


import Distributions.entropy


export boltzmanndist, BAiterations, setuputilityarrays,
       mutualinformation, expectedutility, entropy,
       boltzmannresult2DataFrame, BATheme, 
       BAmarginal2DataFrame, BAconditional2DataFrame, BAresult2DataFrame,
       visualizeBAmarginal, visualizeBAconditional, visualizeBAsolution


#include helper functions for mutual information, expected utiliy
include("InformationTheoryFunctions.jl")

#include helper functions for visualization
include("VisualizationFunctions.jl")



#This function computes p_boltz = 1/Z * p0 * exp(β*ΔU),
#where Z is the normalization constant (partition function)
### arguments:
#p0 ... prior distribution (vector of length N)
#β ... inverse temperature (scalar)
#ΔU ... utility or potential-difference (vector of length N)
### returns:
#p_boltz ... 1/Z * p0 * exp(β*ΔU)
function boltzmanndist(p0::Vector, β, ΔU::Vector)
    p_boltz = p0.*exp(β.*ΔU)
    p_boltz = p_boltz/sum(p_boltz)
    return p_boltz
end




#This function performs Blahut-Arimoto iterations
function BAiterations(pa_init::Vector, β, U_pre::Matrix, Umax::Vector, po::Array, ε_conv::Real, maxiter::Integer)
    pa_new = pa_init    
    card_a = size(U_pre,1)
    card_o = size(U_pre,2)    
    pago = zeros(card_a,card_o)
    
    for iter in 1:maxiter
        pa = deepcopy(pa_new)  #make sure not to just copy the reference
        pa_new = zeros(card_a)       
        for k in 1:card_o
            #update p(a|o)
            pago[:,k] = boltzmanndist(pa,β,vec(U_pre[:,k]))            
            #update p(a)            
            pa_new = pa_new + vec((pago[:,k]')*po[k])
        end

        #check for convergence
        if norm(pa-pa_new) < ε_conv
            return pago, vec(pa_new)
        end
    end
    
    warn("[BAiterations] maximum iteration reached - returning... (results might be inaccurate)")
    return pago, vec(pa_new)  #the squeeze will turn pa into a vector again
end



#Setup pre-evalutated utility matrix and the utility-maximum vector
function setuputilityarrays(a::Vector, o::Vector, utility::Function)
    cardinality_a = length(a) 
    cardinality_o = length(o)

    #pre-compute utilities, find maxima
    U_pre = zeros(cardinality_a, cardinality_o)
    Umax = zeros(cardinality_o)
    for i in 1:cardinality_o
        U_pre[:,i]=utility(a,o[i])
        Umax[i],ind = findmax(U_pre[:,i])
    end
    
    return U_pre, Umax
end

#TODO: include a version of this function that computes the evolution of mutual information
#and expected utility in each iteration and return this as a DataFrame

#TODO: also include a version that computes the above values but only for the 
#final result after iterating

#TODO: perhaps don't expose entropy() (so other code using the method
#remains unaffected)? Maybe insted provide fcn called bitentropy or sth. like that? 

#TODO: Move the BA code into a seperate file such that the main-file
#of the module remains uncluttered. Perhaps move everything into a
#src folder. Look at how this is properly done and also look at the
#structure that the Julia function for generating modules creates.

#TODO: include 2-level BA algorithm(s) here(?)

#TODO: also use 'a' and 'o' in InformationTheoryFunctions.jl

#TODO: document functions (in markdown? look up how to do this properly)

#TODO: write some tests (especially in case future releases break something)

#TODO: adopt src/ test/ structure

end