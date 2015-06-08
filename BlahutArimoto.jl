module BlahutArimoto

#using #dependencies

#import #methods to overload


#include helper functions for mutual information, expected utiliy
include("InformationTheoryFunctions.jl")

#include helper functions for visualization
include("VisualizationFunctions.jl")


export boltzmanndist, BAiterations, setuputilityarrays


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
function BAiterations(pa_init::Vector, β, U_pre::Matrix, Umax::Vector, pω::Array, ε_conv::Real, maxiter::Integer)
    pa_new = pa_init    
    card_a = size(U_pre,1)
    card_ω = size(U_pre,2)    
    pagω = zeros(card_a,card_ω)
    
    for iter in 1:maxiter
        pa = deepcopy(pa_new)  #make sure not to just copy the reference
        pa_new = zeros(card_a)       
        for k in 1:card_ω
            #update p(a|ω)
            pagω[:,k] = boltzmanndist(pa,β,vec(U_pre[:,k]))            
            #update p(a)            
            pa_new = pa_new + vec((pagω[:,k]')*pω[k])
        end

        #check for convergence
        if norm(pa-pa_new) < ε_conv
        	return pagω, vec(pa_new)
        end
    end
    
    warn("[BAiterations] maximum iteration reached - returning... (results might be inaccurate)")
    return pagω, vec(pa_new)  #the squeeze will turn pa into a vector again
end



#Setup pre-evalutated utility matrix and the utility-maximum vector
function setuputilityarrays(a::Vector, ω::Vector, utility::Function)
    cardinality_a = length(a) 
    cardinality_ω = length(ω)

    #pre-compute utilities, find maxima
    U_pre = zeros(cardinality_a, cardinality_ω)
    Umax = zeros(cardinality_ω)
    for i in 1:cardinality_ω
        U_pre[:,i]=utility(a,ω[i])
        Umax[i],ind = findmax(U_pre[:,i])
    end
    
    return U_pre, Umax
end

#TODO: include a version of this function that computes the evolution of mutual information
#and expected utility in each iteration and return this as a DataFrame

#TODO: perhaps also include a version that computes the above values but only for the 
#final result after iterating

#TODO: perhaps don't expose entropy() (so other code using the method
#remains unaffected)? 

#TODO: Move the BA code into a seperate file such that the main-file
#of the module remains uncluttered. Perhaps move everything into a
#src folder. Look at how this is properly done and also look at the
#structure that the Julia function for generating modules creates.

#TODO: include 2-level BA algorithm(s) here(?)

#TODO: also use 'a' and 'ω' in InformationTheoryFunctions.jl


end