#test call for the library

using BlahutArimoto

card_x = 3 #cardinality x
card_ϕ = 2 #cardinality ϕ
β = 1 #inverse temperature
ε = 0.000001 #convergence critetion for BAiterations
maxiter = 5000 #maximum number of BA iterations

#set up uniform p(ϕ)
pϕ = ones(card_ϕ)/card_ϕ 

#initialize p(x) uniformly
px_init = ones(card_x)/card_x 


#cosine utility function (returns pre-computed utilities and maximum for each y)
function cosineutility(cardinality_x, cardinality_ϕ)
    #set up x ∈ (0,π/2)
    xvec = linspace(0,pi/2,cardinality_x)
    #set up ϕ ∈ (0,π/4)
    ϕvec = linspace(0,pi/4,cardinality_ϕ)

    #set up the utility function
    #utility is cosine, ϕ acts as a phase shift
    function U(x,ϕ)
        cos(x-ϕ)
    end

    #pre-compute utilities, find maxima
    U_pre, Umax = setuputilityarrays(xvec,ϕvec,U)
    
    return U_pre, Umax, xvec, ϕvec
end


#exemplary usage
U_pre, Umax, xvec, ϕvec = cosineutility(card_x, card_ϕ)
pxgϕ,px = BAiterations(px_init, β, U_pre, Umax, pϕ, ε, maxiter)

U_pre,pxgϕ,px
