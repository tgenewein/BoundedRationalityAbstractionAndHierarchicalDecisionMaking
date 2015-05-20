######################################################################
#This is intended to be part of the module BlahutArimoto
######################################################################

using Distances, Distributions.Distribution

import Distributions.entropy #the function entropy() will be overwritten here

export  mutualinformation, expectedutility, entropy


#functions for computing mutual informations (in bits)
function mutualinformation(py::Vector, px::Vector, pxgiveny::Matrix)    
    card_y = size(py,1)
    if size(pxgiveny,1)==card_y
        rowwise = true;
    elseif size(pxgiveny,2)==card_y
        rowwise = false;
    else
        error("Dimensionality of py and pxgiveny does not match!")
    end
    
    MI = 0
    for i in 1:card_y
        if rowwise
            MI += py[i] * kl_divergence(vec(pxgiveny[i,:]),px)/log(2) #from package Distances.jl, divide by log(2) for bits
        else
            MI += py[i] * kl_divergence(vec(pxgiveny[:,i]),px)/log(2) #from package Distances.jl, divide by log(2) for bits
        end
    end
    
    return MI
end



#function for computing the expected utility
#pxgiveny and umatrix must have the same dimensionality
function expectedutility(py::Vector, pxgiveny::Matrix, umatrix::Matrix)
    card_y = size(py,1)
    card_x = size(px,1)
    if size(pxgiveny,1)==card_y
        rowwise = true;
    elseif size(pxgiveny,2)==card_y
        rowwise = false;
    else
        error("Dimensionality of py and pxgiveny does not match!")
    end
    
    EU = 0
    for i in 1:card_y
        if rowwise
            EU += py[i] * sum(pxgiveny[i,:] .* umatrix[i,:])
        else
            EU += py[i] * sum(pxgiveny[:,i] .* umatrix[:,i])
        end
    end
    
    
    return EU
end



#Also expose entropy() from Distributions.jl
function entropy(d::Distribution)
	return Distributions.entropy(d,2) #in bits
end