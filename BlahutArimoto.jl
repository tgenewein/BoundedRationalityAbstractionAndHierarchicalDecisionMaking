module BlahutArimoto

#using #dependencies

#import #methods to overload


#include helper functions for mutual information, expected utiliy
include("InformationTheoryFunctions.jl")

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
function BAiterations(px_init::Vector, β, U_pre::Matrix, Umax::Vector, pω::Array, maxiter::Integer)
    px_new = px_init    
    card_ω = size(U_pre,1)
    card_x = size(U_pre,2)
    pxgω = zeros(card_ω,card_x)
    
    for iter in 1:maxiter
        px = deepcopy(px_new)  #make sure not to just copy the reference
        px_new = zeros(card_x)       
        for k in 1:card_ω
            #update p(x|ω)
            pxgω[k,:] = boltzmanndist(px,β,squeeze(U_pre[k,:],1))            
            #update p(x)            
            px_new = px_new + squeeze([pxgω[k,:]*pω[k]],1)
        end
    end
    
    return pxgω, vec(px_new)  #the squeeze will turn px into a vector again
end

#Setup pre-evalutated utility matrix and the utility-maximum vector
function setuputilityarrays(x::Vector, ω::Vector, utility::Function)
    cardinality_x = length(x) 
    cardinality_ω = length(ω)

    #pre-compute utilities, find maxima
    U_pre = zeros(cardinality_ω, cardinality_x)
    Umax = zeros(cardinality_ω)
    for i in 1:cardinality_ω
        U_pre[i,:]=utility(x,y[i])
        Umax[i],ind = findmax(U_pre[i,:])
    end
    
    return U_pre, Umax
end

#TODO: include a version of this function that computes the evolution of mutual information
#and expected utility in each iteration and return this as a DataFrame

#TODO: perhaps also include a version that computes the above values but only for the 
#final result after iterating

#TODO: include 2-level BA algorithm(s) here(?)


end