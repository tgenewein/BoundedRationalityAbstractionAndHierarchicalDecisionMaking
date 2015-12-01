
#functions for computing mutual informations (in bits)
#po is the distribution where the KL is averaged over
#the KL measures going from px to pxgy
function mutualinformation(py::Vector, px::Vector, pxgy::Matrix; return_nats=false)
    card_y = size(py,1)
    card_x = size(px,1)
    if (size(pxgy,1)!=card_x) || (size(pxgy,2)!=card_y)
        error("Dimensionality of p(x|y) does not match p(x), p(y)!")
    end

    MI = 0
    for i in 1:card_y
        if return_nats
          MI += py[i] * kl_divergence_nats(vec(pxgy[:,i]),px)
        else
          MI += py[i] * kl_divergence_bits(vec(pxgy[:,i]),px)
        end
    end

    return MI
end


#functions for computing the conditional mutual information
#I(X;Y|Z)(in bits)
function conditional_mutualinformation(py::Vector, pzgy::Matrix, pxgz::Matrix, pxgzy; return_nats=false)
    #I(X;Y|Z) = ∑_y p(y) DKL( p(x|z,y)||p(x|z) )
    #I(X;Y|Z) = ∑_y p(y) ∑_z p(z|y) ∑_x p(x|z,y) log( p(x|z,y)/p(x|z) )

    card_y = length(py)
    card_z = size(pzgy,1)


    MI = 0
    for j in 1:card_y
        for k in 1:card_z
            if return_nats
              MI += py[j]*pzgy[k,j] * kl_divergence_nats( vec(pxgzy[:,k,j]), vec(pxgz[:,k]))
            else
              MI += py[j]*pzgy[k,j] * kl_divergence_bits( vec(pxgzy[:,k,j]), vec(pxgz[:,k]))
            end
        end
    end

    return MI
end




#function for computing the expected utility
#pagw and U_pre must have the same dimensionality
function expectedutility(pw::Vector, pagw::Matrix, U_pre::Matrix)
    #E[U] = ∑_a,w p(w)p(a|w) U(a,w)
    card_w = size(pw,1)
    card_a = size(pagw,1)
    if (size(pagw,2)!=card_w) || (size(U_pre,1)!=card_a) || (size(U_pre,2)!=card_w)
        error("Dimensionality of p(a|w), U_pre(a,w) and p(w) does not match!")
    end

    EU = 0
    for i in 1:card_w
            EU += pw[i] * sum(pagw[:,i] .* U_pre[:,i])
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

#Entropy in bits for a discrete distribution represented as a vector
function entropybits(p::Vector)
    return entropybits(Categorical(p))
end

#Entropy in nats (using entropy from Distributions.jl)
function entropynats(d::Distribution)
    return Distributions.entropy(d) #in bits
end

#Entropy in nats for a discrete distribution represented as a vector
function entropynats(p::Vector)
    return entropybits(Categorical(p))
end



#Kullback-Leibler divergence in nats
function kl_divergence_nats(p_x::Vector, p0_x::Vector)
    #D_KL_bits = ∑_x p(x) log (p(x)/p0(x))

    if sum(p0_x.==0) > 0
        error("Zeros in denominator before kl_divergence computation!")
    end

    kl_div = kl_divergence(p_x, p0_x) #using function from Distances.jl

    return kl_div
end

#Kullback-Leibler divergence in bits
function kl_divergence_bits(p_x::Vector, p0_x::Vector)
    return nats_to_bits(kl_divergence_nats(p_x, p0_x))
end


#conversion functions for going from bits to nats and vice-versa
function nats_to_bits(x)
  return x/log(2)
end

function bits_to_nats(x)
  return x*log(2)
end


#compute value of rate-distortion objective (avg ΔF)
#make sure to provide I in nats!
function RDobjective(EU,I_nats,β)
    return EU-I_nats/β
end

#Objective-value for the three-variable general case
#make sure to provide all mutual information terms in nats!
function ThreeVArRDobjective(EU, I_ow_nats, I_ao_nats, I_awgo_nats, β1, β2, β3)
    if(β3==0)
        #sequential case - I(A;W|O) should be zero and since β3=Inf → ∞ * 0 = NaN
        #handle this by using a tiny β3 - if I(A;W|O) is nonzero, this should be easily detectable through the huge
        #value of the objective
        β3 = eps()
    end
    return EU - (1/β1)*I_ow_nats - (1/β2)*I_ao_nats - (1/β3)*I_awgo_nats
end





#compute I(A;W), H(A), H(A|W), E[U] and E[U]-I(A;W)/β
function analyzeBAsolution(pw::Vector, pa::Vector, pagw::Matrix, U_pre::Matrix, β)
    #compute I(A;W)
    I = mutualinformation(pw,pa,pagw)
    #compute H(A)
    Ha = entropybits(pa)
    #compute H(A|W)
    Hagw = Ha-I
    #compute EU
    EU = expectedutility(pw,pagw,U_pre)
    #compute value of objective
    RDobj = RDobjective(EU,bits_to_nats(I),β)

    return I, Ha, Hagw, EU, RDobj
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
    #println("1: ∑p(o) = $(sum(po))")
    Ho = entropybits(po)

    #compute H(A)
    #println("2: ∑p(a) =  $(sum(pa))")
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
    EU = expectedutility(pw,pagw,U_pre)

    #compute value of objective
    ThreeVarRDobj = ThreeVArRDobjective(EU, bits_to_nats(I_ow), bits_to_nats(I_ao), bits_to_nats(I_awgo), β1, β2, β3)

    return I_ow, I_ao, I_awgo, I_aw, Ho, Ha, Hogw, Hago, Hagow, Hagw, EU, ThreeVarRDobj
end
