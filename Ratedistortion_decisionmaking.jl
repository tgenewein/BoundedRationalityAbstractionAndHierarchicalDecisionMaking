#test call for the library

#change path to actual folder containing the files
#this seems to be an issue with Sublime IJulia
#cd("GSOSpecialIssue/Code/") 

using BlahutArimoto

card_x = 3 #cardinality x
card_ω = 2 #cardinality ω
β = 1 #inverse temperature

#set up uniform p(ω)
pω = ones(card_ω)/card_ω 

#initialize p(x) uniformly
px_init = ones(card_x)/card_x 



#cosine utility function (returns pre-computed utilities and maximum for each y)
function CosineUtility(cardinality_x, cardinality_y)
    #set up x ∈ (0,π/2)
    xvec = linspace(0,pi/2,cardinality_x)
    #set up y ∈ (0,π/4)
    yvec = linspace(0,pi/4,cardinality_y)

    #set up the utility function
    #utility is cosine, ω acts as a phase shift
    function U(x,ω)
        cos(x-ω)
    end

    #pre-compute utilities, find maxima
    U_pre = zeros(cardinality_y, cardinality_x)
    Umax = zeros(cardinality_y)
    for i in 1:cardinality_y
        U_pre[i,:]=U(xvec,yvec[i])
        Umax[i],ind = findmax(U_pre[i,:])
    end
    
    return U_pre, Umax
end


#exemplary usage
U_pre, Umax = CosineUtility(card_x, card_ω)
pxgω,px = BAItarations(px_init,β,U_pre,Umax,pω,5000)

U_pre,pxgω,px
