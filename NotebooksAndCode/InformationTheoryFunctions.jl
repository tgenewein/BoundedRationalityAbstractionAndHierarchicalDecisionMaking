
#functions for computing mutual informations (in bits)
#po is the distribution where the KL is averaged over
#the KL measures going from pa to pago
function mutualinformation(po::Vector, pa::Vector, pago::Matrix)    
    card_o = size(po,1)
    card_a = size(pa,1)
    if (size(pago,1)!=card_a) || (size(pago,2)!=card_o)
        error("Dimensionality of p(a|o) does not match p(o), p(a)!")
    end
    
    MI = 0
    for i in 1:card_o
        MI += po[i] * kl_divergence_bits(vec(pago[:,i]),pa)
    end
    
    return MI
end


#functions for computing the conditional mutual information
#I(A;W|O)(in bits)
function conditional_mutualinformation(pw::Vector, pogw::Matrix, pago::Matrix, pagow)  
    #I(A;W|O) = ∑_w p(w) DKL( p(a|o,w)||p(a|o) )
    #I(A;W|O) = ∑_w p(w) ∑_o p(o|w) ∑_a p(a|o,w) log( p(a|o,w)/p(a|o) )
    
    #TODO: dimensionality check?
    
    card_w = length(pw)
    card_o = size(pogw,1)    
    
    
    MI = 0
    for j in 1:card_w
        for k in 1:card_o
            MI += pw[j]*pogw[k,j] * kl_divergence_bits( vec(pagow[:,k,j]), vec(pago[:,k]))
        end
    end   
    
    return MI
end




#function for computing the expected utility
#pxgiveny and umatrix must have the same dimensionality
#pago and U_pre must have the same dimensionality
function expectedutility(po::Vector, pago::Matrix, U_pre::Matrix)
    card_o = size(po,1)
    card_a = size(pago,1)
    if (size(pago,2)!=card_o) || (size(U_pre,1)!=card_a) || (size(U_pre,2)!=card_o)
        error("Dimensionality of p(a|o), U_pre(a,o) and p(o) does not match!")
    end
    
    EU = 0
    for i in 1:card_o
        #TODO: clean up
        #if rowwise
        #    EU += po[i] * sum(pago[i,:] .* U_pre[i,:])
        #else
            EU += po[i] * sum(pago[:,i] .* U_pre[:,i])
        #end
    end
    
    
    return EU
end


#This function assumes that the utility function U(a,w) is not a function of the percept o
function expectedutility(pw::Vector, pogw::Matrix, pagow, U_pre::Matrix)
    #E[U] = ∑_a,o,w p(w)p(o|w)p(a|o,w) U(a,w)
    
    #reuse the function that computes E[U] for ∑_a,w p(w)p(a|w) U(a,w)
    #to do so, compute p(a|w)
    pagw = marginalizeo(pogw,pagow)
    
    return expectedutility(pw,pagw,U_pre)
end




#Entropy in bits (using entropy from Distributions.jl)
function entropybits(d::Distribution)
    return Distributions.entropy(d,2) #in bits
end

#Entropy in bits for an discrete distribution represented as a vector
function entropybits(p::Vector)
    return entropybits(Categorical(p))
end

#Explicitly provide a function for the log in bits here.
#The rationale behind this is that it makes it easily possible to spot all the 
#places (in the code) to change if one wants to use the nats (natural logarithm) intead of bits.
function log_bits(x)
    return log2(x)
end

#Kullback-Leibler divergence in bits 
function kl_divergence_bits(p_x::Vector, p0_x::Vector)
    #D_KL_bits = ∑_x p(x) log2 (p(x)/p0(x))
    return kl_divergence(p_x, p0_x)/log(2) #using function from Distances.jl
end





#compute value of rate-distortion objective (avg ΔF)
function RDobjective(EU,I,β)
    return EU-I/β
end

#Objective-value for the three-variable general case
function ThreeVArRDobjective(EU, I_ow, I_ao, I_awgo, β1, β2, β3)
    return EU - (1/β1)*I_ow - (1/β2)*I_ao - (1/β3)*I_awgo
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



#compute mutual informations, entropies and value of objective for three-variable general case
function analyze_three_var_BAsolution(pw::Vector, po::Vector, pa::Vector, pogw::Matrix,
    pago::Matrix, pagow, pagw::Matrix, U_pre::Matrix, β1, β2, β3)
    
    #compute I(O;W)
    I_ow = mutualinformation(pw,po,pogw)
    
    #compute I(A;O)
    I_ao = mutualinformation(po,pa,pago)
    
    #compute I(A;W|O)
    I_awgo = conditional_mutualinformation(pw, pogw, pago, pagow)

    #compute I(A;W)
    I_aw = mutualinformation(pw,pa,pagw)
    
    #compute H(O)
    #s1 = sum(po) 
    println("1: ∑p(o) = $(sum(po))") #TODO: rather wrap this in a try-catch block
    Ho = entropybits(po)
    
    #compute H(A)
    #s2 = sum(pa)
    println("2: ∑p(a) =  $(sum(pa))") #TODO: rather wrap this in a try-catch block
    Ha = entropybits(pa)
    
    #compute H(O|W)
    Hogw = Ho - I_ow
    
    #compute H(A|O)
    Hago = Ha - I_ao
    
    #compute H(A|O,W)
    Hagow = Hago - I_awgo

    #compute H(A|W)
    Hagw = Ha - I_aw
    
    
    #compute EU
    #TODO: this is already computed in the main-iterations, don't recompute it here!
    #Perhaps allow the EU to be passed as an optional argument and if it's passed,
    #don't recompute it
    EU = expectedutility(pw,pogw,pagow,U_pre)
    
    #compute value of objective
    ThreeVarRDobj = ThreeVArRDobjective(EU, I_ow, I_ao, I_awgo, β1, β2, β3)

    return I_ow, I_ao, I_awgo, I_aw, Ho, Ha, Hogw, Hago, Hagow, Hagw, EU, ThreeVarRDobj
end




#TODO: add functions for conditional entropy?