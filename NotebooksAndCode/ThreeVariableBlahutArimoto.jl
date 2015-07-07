function compute_marginals(pw::Vector, pogw::Matrix, pagow)
    
    card_o = size(pogw,1)
    card_a = size(pagow,1)
    
    #compute p(o)
    #p(o) = ∑_w p(o|w)p(w)
    po = pogw * pw
    po = po / sum(po) #TODO: does this improve convergence?


    #compute p(a|o)
    #p(a|o) = ∑_w p(w|o)p(a|o,w)   with p(w|o) = p(o|w)p(w)/p(o)
    pago = zeros(card_a, card_o)
    for k in 1:card_o
        #compute p(w|o=k)
        pwgo_k = vec(pogw[k,:]).*pw / po[k]
        #compute p(a|o=k)
        pago[:,k] = squeeze(pagow[:,k,:],2) * pwgo_k

        #normalize
        pago[:,k] = pago[:,k] / sum(pago[:,k]) #TODO: does this improve convergence?
    end


    #compute p(a)
    #p(a) = ∑_w,o p(w)p(o|w)p(a|o,w)
    #compute p(a|w)
    pagw = marginalizeo(pogw, pagow)
    #p(a) = ∑_w p(a|w)p(w)
    pa = pagw * pw
    pa = pa / sum(pa) #TODO: does this improve convergence?


    #TODO: renormalize marginals (in principle this should not be necessary,
    #but in practice they do not sum to one in the early iteration steps!)

    
    return po, pa, pago, pagw
end



function marginalizeo(pogw::Matrix, pagow)
    #TODO: is this correct?
    card_a = size(pagow,1)
    card_w = size(pogw,2)
       
    #compute p(a|w)
    pagw = zeros(card_a,card_w)
    #pagw = ones(card_a,card_w)    #this should be zeros(), but there is (currently) some bug 
                                  #in Julia that causes the kernel to die when using zeros(...) in this line,
                                  #therefore, use ones(...) since it's just about pre-allocation and the value
                                  #doesn't make a difference
    for j in 1:card_w
        #p(a|w) = ∑_o p(o|w)p(a|o,w)
        pagw[:,j] = pagow[:,:,j] * pogw[:,j]
    end
    
    return pagw
end




#This function performs Blahut-Arimoto iterations for the three-variable general case
function threevarBAiterations(pogw_init::Matrix, pagow_init, β1, β2, β3, 
    U_pre::Matrix, pw::Vector, ε_conv::Real, maxiter::Integer;
    compute_performance::Bool=false, performance_per_iteration::Bool=false,
    performance_as_dataframe::Bool=false)
    
    card_a = size(U_pre,1)
    card_w = size(U_pre,2)
    card_o = size(pogw_init,1) 
    
   
    #p(o|w)
    pogw = pogw_init    
    #p(a|o,w)
    pagow = pagow_init

 
    #initialize marginals consistently
    po_new, pa_new, pago_new, pagw = compute_marginals(pw, pogw, pagow) 
    

    #if performance measures don't need to be returned, don't compute them per iteration
    if compute_performance==false
        performance_per_iteration = false
    end 

    #preallocate if necessary
    EU_i = zeros(maxiter) #this is always necessary
    if performance_per_iteration 
        I_ow_i = zeros(maxiter)  #I(O;W)
        I_ao_i = zeros(maxiter)  #I(A;O)
        I_awgo_i = zeros(maxiter)  #I(A;W|O)
        Ha_i = zeros(maxiter)  #H(A)
        Ho_i = zeros(maxiter)  #H(O)
        Hago_i = zeros(maxiter)  #H(A|O)
        Hogw_i = zeros(maxiter)  #H(O|W)
        Hagow_i= zeros(maxiter)  #H(A|O,W)
        ThreeVarRDobj_i = zeros(maxiter)
    end
    
    #main iteration
    iter = 0 #initialize counter, so it persists beyond the loop
    for iter in 1:maxiter
        pa = deepcopy(pa_new)  #make sure not to just copy the reference
        #pa_new = zeros(card_a) #TODO: do you need to initialize?
        po = deepcopy(po_new)
        #po_new = zeros(card_o) #TODO: do you need to initialize?
        pago = deepcopy(pago_new)
        #pago_new = zeros(card_a,card_o) #TODO: do you need to initialize
            


        #compute p(o|w)
        #p(o|w) ∝ p(o) exp( β1 (E[U] - 1/β2 DKL(p(a|o,w)||p(a))) - β1 DKL(p(a|o,w)||p(a|o)) (1/β3-1/β2) )

        #------- E[U] (of previous iteration) ---------#            
        if iter==1
            EU_last = expectedutility(pw,pogw,pagow,U_pre)
        else
            EU_last = EU_i[iter-1]
        end

        #------- compute the two KL terms -----------#
        #TODO: rather than specifying the KL in bits here, do it in InformationTheoryFunctions,
        #similar to entroybits
        DKL_a = zeros(card_o,card_w)
        DKL_ago = zeros(card_o,card_w)
        
        for j in 1:card_w
            for k in 1:card_o
                DKL_a[k,j] = kl_divergence(vec(pagow[:,k,j]),pa)/log(2) #from package Distances.jl, divide by log(2) for bits
                DKL_ago[k,j] = kl_divergence(vec(pagow[:,k,j]),vec(pago[:,k]))/log(2) #from package Distances.jl, divide by log(2) for bits
            end
        end
        

        pogw_util = EU_last - 1/β2 * DKL_a - (1/β3-1/β2) * DKL_ago
        #TODO: can you really use EU here, or should the expectation depend on the conditioned vars o,w?
        
        for j in 1:card_w
            #TODO: replace this with the function BoltzmannDist
            pogw[:,j] = boltzmanndist(po, β1, vec(pogw_util[:,j]))
            #pogw_j = po .* exp(β1 * powg_util[:,j])
            #pogw[:,j] = pogw_j ./ sum(pogw_j)  #normalize (TODO: is this correct?)
        end
        
        

        #2) compute p(a|o,w)
        #p(a|o,w) ∝ p(a|o) exp( β3 U(a,w) - β3/β2 log(p(a|o)/p(a)) )
        for k in 1:card_o
            for j in 1:card_w
                #TODO: replace this with the function BoltzmannDist
                
                #for a in 1:card_a
                #    pagow[i,k,j] = pago[i,k] * exp( β3*U_pre[i,w] - β3/β2*log(pago[i,k]/pa[i])/log(2) #divide by log(2) for bits                                        
                #end                
                #normalize (TODO: is this normalization correct?)
                #pagow[:,k,j] = pagow[:,k,j] / sum(pagow[:,k,j])                
                pagow_util_kj = U_pre[:,j] - (1/β2)*log(pago[:,k]./pa)/log(2) #divide by log(2) for bits                    
                pagow[:,k,j] = boltzmanndist(vec(pago[:,k]), β3, pagow_util_kj)
            end
        end
        

        #3) update the marginals p(o), p(a), p(a|o)
        po_new, pa_new, pago_new, pagw = compute_marginals(pw, pogw, pagow) 
        
        
        #------- compute E[U] (using p(a|w)) ---------#            
        EU_i[iter] = expectedutility(pw,pagw,U_pre)
        
        
        #TODO: is it better to immediately use the pxx_new quantities, or just update all of them
        #after each iteration (the latter is implemented right now)?
        #Does the order of the equations play any role?

        #compute entropic quantities (if requested with additional parameter)
        if performance_per_iteration
            I_ow_i[iter], I_ao_i[iter], I_awgo_i[iter], 
            Ho_i[iter], Ha_i[iter], Hogw_i[iter], Hago_i[iter],
            Hagow_i[iter], EU_i[iter], ThreeVarRDobj_i[iter] = analyze_three_var_BAsolution(pw, po_new, pa_new,
                                                               pogw, pago_new, pagow, U_pre, β1, β2, β3)
        end

        #check for convergence
        #TODO: include other terms as well?
        if (norm(pa-pa_new) + norm(po-po_new)) < ε_conv            
            break
        end
        
    end
    
    #check if iteration limit has been reached (before convergence)
    if iter == maxiter
        warn("[Three variable BAiterations] maximum iteration reached - returning... (results might be inaccurate)")
    end



    #return results
    if compute_performance == false
        return po_new, pa_new, pogw, pago_new, pagow 
    else
        if performance_per_iteration == false
            #compute performance measures for final solution
            I_ow, I_ao, I_awgo, Ho, Ha, Hogw, Hago, Hagow, EU, ThreeVarRDobj = analyze_three_var_BAsolution(pw, po_new,
                                                                               pa_new, pogw, pago_new, pagow, U_pre, β1, β2, β3)
        else
            #"cut" valid results from preallocated vector
            I_ow = I_ow_i[1:iter]
            I_ao = I_ao_i[1:iter]
            I_awgo = I_awgo_i[1:iter]
            Ho = Ho_i[1:iter]
            Ha = Ha_i[1:iter]
            Hogw = Hogw_i[1:iter]
            Hago = Hago_i[1:iter]
            Hagow = Hagow_i[1:iter]
            EU = EU_i[1:iter]
            ThreeVarRDobj = ThreeVarRDobj_i[1:iter]
        end

        #if needed, transform to data frame
        if performance_as_dataframe == false
            return po_new, pa_new, pogw, pago_new, pagow, I_ow, I_ao, I_awgo, Ho, Ha, Hogw, Hago, Hagow, EU, ThreeVarRDobj
        else
            performance_df = performancemeasures2DataFrame(I_ow, I_ao, I_awgo, Ho, Ha, Hogw, Hago, Hagow, EU, ThreeVarRDobj)
            return po_new, pa_new, pogw, pago_new, pagow, performance_df 
        end
    end
    
end


#TODO: provide a function that initializes p(o|w) and p(a|o,w) either uniformly or randomly


