
#functions for computing mutual informations (in bits)
function mutualinformation(po::Vector, pa::Vector, pago::Matrix)    
    card_o = size(po,1)
    if size(pago,1)==card_o
        rowwise = true;
    elseif size(pago,2)==card_o
        rowwise = false;
    else
        error("Dimensionality of p(o) and p(a|o) does not match!")
    end
    
    MI = 0
    for i in 1:card_o
        if rowwise
            MI += po[i] * kl_divergence(vec(pago[i,:]),pa)/log(2) #from package Distances.jl, divide by log(2) for bits
        else
            MI += po[i] * kl_divergence(vec(pago[:,i]),pa)/log(2) #from package Distances.jl, divide by log(2) for bits         
        end
    end
    
    return MI
end



#function for computing the expected utility
#pxgiveny and umatrix must have the same dimensionality
#pago and U_pre must have the same dimensionality
function expectedutility(po::Vector, pago::Matrix, U_pre::Matrix)
    card_o = size(po,1)
    if size(pago,1)==card_o
        rowwise = true;
    elseif size(pago,2)==card_o
        rowwise = false;
    else
        error("Dimensionality of po and p(a|o) does not match!")
    end
    
    EU = 0
    for i in 1:card_o
        if rowwise
            EU += po[i] * sum(pago[i,:] .* U_pre[i,:])
        else
            EU += po[i] * sum(pago[:,i] .* U_pre[:,i])
        end
    end
    
    
    return EU
end


#Entropy in bits (using entropy from Distributions.jl)
function entropybits(d::Distribution)
    return Distributions.entropy(d,2) #in bits
end

#Entropy in bits for an discrete distribution represented as a vector
function entropybits(p::Vector)
    return entropybits(Categorical(p))
end


#compute value of rate-distortion objective (avg ΔF)
function RDobjective(EU,I,β)
    return EU-I/β
end

#compute I(A;O), H(A), H(A|O), E[U] and E[U]-I(A;O)/β
function analyzeBAsolution(po::Vector, pa::Vector, pago::Matrix, U_pre::Matrix, β)
    #compute I(a;o)
    I = mutualinformation(po,pa,pago)
    #compute H(a)
    Ha = entropybits(pa)
    #compute H(a|o)?
    Hago = Ha-I
    #compute EU
    EU = expectedutility(po,pago,U_pre)
    #compute value of objective
    RDobj = RDobjective(EU,I,β)

    return I, Ha, Hago, EU, RDobj
end


#TODO: add functions for conditional entropy?