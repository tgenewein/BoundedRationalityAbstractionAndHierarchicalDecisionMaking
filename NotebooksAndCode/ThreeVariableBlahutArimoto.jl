function compute_marginals(pw::Vector, pogw::Matrix, pagow)
    
    card_o = size(pogw,1)
    card_a = size(pagow,1)
    
    #compute p(o)
    #p(o) = ∑_w p(o|w)p(w)
    po = pogw * pw

    #add some small value to prevent NaNs in the KL-terms
    po += eps()
    po = po / sum(po) #TODO: does this improve convergence?


    #compute p(a|o)
    #p(a|o) = ∑_w p(w|o)p(a|o,w)   with p(w|o) = p(o|w)p(w)/p(o)
    pago = zeros(card_a, card_o)
    for k in 1:card_o
        #compute p(w|o=k)
        pwgo_k = vec(pogw[k,:]).*pw / po[k]
        #compute p(a|o=k)
        pago[:,k] = squeeze(pagow[:,k,:],2) * pwgo_k


        #add some small value to prevent NaNs in the KL-terms
        pago[:,k] += eps()
        pago[:,k] = pago[:,k] / sum(pago[:,k]) #TODO: does this improve convergence?
    end


    #compute p(a)
    #p(a) = ∑_w,o p(w)p(o|w)p(a|o,w)
    #compute p(a|w)
    pagw = marginalizeo(pogw, pagow)
    #p(a) = ∑_w p(a|w)p(w)
    pa = pagw * pw

    #add some small value to prevent NaNs in the KL-terms
    pa += eps()
    pa = pa / sum(pa) #TODO: does this improve convergence?


    #TODO: renormalize marginals (in principle this should not be necessary,
    #but in practice they do not sum to one in the early iteration steps!)

    #TODO: adding an epsilon should not make much of a difference, but 
    #re-normalizing afterwards might do so, on the other hand... the distribution
    #should already more or less sum to one, so getting rid of the zero-entries should 
    #be fine

    #TODO: if you really leave the function with adding an eps (and potentially renormalizing)
    #indicate this in the function name somehow, and perhaps even offer both versions!

    
    return po, pa, pago, pagw
end



function marginalizeo(pogw::Matrix, pagow)
    card_a = size(pagow,1)
    card_w = size(pogw,2)
       
    #compute p(a|w)
    pagw = zeros(card_a,card_w)

    for j in 1:card_w
        #p(a|w) = ∑_o p(o|w)p(a|o,w)
        pagw[:,j] = pagow[:,:,j] * pogw[:,j]
    end
    
    return pagw
end






#This function performs Blahut-Arimoto iterations for the three-variable general case
#and initializes p(o|w) and p(a|o,w) either uniformly or randomly, depending on the value
#of the optional argument 'init_uniform'
function threevarBAiterations(cardinality_obs::Integer, β1, β2, β3, U_pre::Matrix, pw::Vector,
                              ε_conv::Real, maxiter::Integer; compute_performance::Bool=false,
                              performance_per_iteration::Bool=false, performance_as_dataframe::Bool=false,
                              init_uniformly = false)
    
    #----- Initialization -----#
    num_worldstates = length(pw)
    num_acts = size(U_pre,1)

    #initialize p(o|w) and p(a|o,w)
    if init_uniformly
        #uniform initialization
        p_ogw_init = ones(cardinality_obs, num_worldstates)  
        p_agow_init = ones(num_acts, cardinality_obs, num_worldstates) 
    else
        #random initialization
        p_ogw_init = rand(cardinality_obs, num_worldstates) 
        p_agow_init = rand(num_acts, cardinality_obs, num_worldstates)
    end
        
    #normalize
    for j in 1:num_worldstates    
        #p(o|w)
        p_ogw_init[:,j] = p_ogw_init[:,j] / sum(p_ogw_init[:,j])
        
        #p(a|o,w)
        for k in 1:cardinality_obs
            p_agow_init[:,k,j] = p_agow_init[:,k,j] / sum(p_agow_init[:,k,j])
        end
    end


    #------- Blahut-Arimoto call --------#
    #Blahut-Arimoto iterations for the three-variable general case
    return threevarBAiterations(p_ogw_init, p_agow_init, β1, β2, β3, U_pre, p_w, ε, maxiter, 
                                compute_performance=compute_performance,
                                performance_per_iteration=performance_per_iteration,
                                performance_as_dataframe=performance_as_dataframe)
    
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
    #TODO: perhaps it would be better to choose the marginals and initialize the
    #conditionals consistently (for instance for the sequential case, p(a|o)=p(a|o,w) ∀w,
    #with random initializations, this can not be ensured that's perhaps why the iterations
    #run into numerical issues - with proper initialization this might be alleviated? However,
    #at least the unifomr initialization should do this as well, but perhaps it is too symmetric,
    #and does not allow the iterations to do anything?)
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
        I_aw_i = zeros(maxiter) #I(A;W)
        Ha_i = zeros(maxiter)  #H(A)
        Ho_i = zeros(maxiter)  #H(O)
        Hago_i = zeros(maxiter)  #H(A|O)
        Hogw_i = zeros(maxiter)  #H(O|W)
        Hagow_i = zeros(maxiter)  #H(A|O,W)
        Hagw_i = zeros(maxiter) #H(A|W)
        ThreeVarRDobj_i = zeros(maxiter)
    end
    
    #main iteration
    iter = 0 #initialize counter, so it persists beyond the loop
    for iter in 1:maxiter
        pa = deepcopy(pa_new)  #make sure not to just copy the reference
        po = deepcopy(po_new)
        pago = deepcopy(pago_new)            


        #compute p(o|w)
        #p(o|w) ∝ p(o) exp( β1 (E[U] - 1/β2 DKL(p(a|o,w)||p(a))) - β1 DKL(p(a|o,w)||p(a|o)) (1/β3-1/β2) )

        #------- E[U] (of previous iteration) ---------#            
        if iter==1
            EU_last = expectedutility(pw,pogw,pagow,U_pre)
        else
            EU_last = EU_i[iter-1]
        end

        #------- compute the two KL terms -----------#
        DKL_a = zeros(card_o,card_w)
        DKL_ago = zeros(card_o,card_w)
        
        for j in 1:card_w
            for k in 1:card_o
                DKL_a[k,j] = kl_divergence_bits(vec(pagow[:,k,j]),pa)
                DKL_ago[k,j] = kl_divergence_bits(vec(pagow[:,k,j]),vec(pago[:,k]))
            end
        end
        

        pogw_util = EU_last - 1/β2 * DKL_a - (1/β3-1/β2) * DKL_ago
        #TODO: can you really use EU here, or should the expectation depend on the conditioned vars o,w?
        
        for j in 1:card_w
            pogw[:,j] = boltzmanndist(po, β1, vec(pogw_util[:,j]))
        end
        
        

        #2) compute p(a|o,w)
        #p(a|o,w) ∝ p(a|o) exp( β3 U(a,w) - β3/β2 log(p(a|o)/p(a)) )
        for k in 1:card_o
            for j in 1:card_w              
                pagow_util_kj = U_pre[:,j] - (1/β2)*log_bits(pago[:,k]./pa)                
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
            I_ow_i[iter], I_ao_i[iter], I_awgo_i[iter], I_aw_i[iter],
            Ho_i[iter], Ha_i[iter], Hogw_i[iter], Hago_i[iter],
            Hagow_i[iter], Hagw_i[iter],
            EU_i[iter], ThreeVarRDobj_i[iter] = analyze_three_var_BAsolution(pw, po_new, pa_new, pogw, pago_new,
                                                                             pagow, pagw, U_pre, β1, β2, β3)
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
        return po_new, pa_new, pogw, pago_new, pagow, pagw
    else
        if performance_per_iteration == false
            #compute performance measures for final solution
            I_ow, I_ao, I_awgo, I_aw, Ho, Ha, Hogw, Hago, Hagow, Hagw, EU, ThreeVarRDobj = analyze_three_var_BAsolution(pw, po_new,
                                                                                           pa_new, pogw, pago_new, pagow, pagw, U_pre, β1, β2, β3)
        else
            #"cut" valid results from preallocated vector
            I_ow = I_ow_i[1:iter]
            I_ao = I_ao_i[1:iter]
            I_awgo = I_awgo_i[1:iter]
            I_aw = I_aw_i[1:iter]
            Ho = Ho_i[1:iter]
            Ha = Ha_i[1:iter]
            Hogw = Hogw_i[1:iter]
            Hago = Hago_i[1:iter]
            Hagow = Hagow_i[1:iter]
            Hagw = Hagw_i[1:iter]
            EU = EU_i[1:iter]
            ThreeVarRDobj = ThreeVarRDobj_i[1:iter]
        end

        #if needed, transform to data frame
        if performance_as_dataframe == false
            return po_new, pa_new, pogw, pago_new, pagow, pagw, I_ow, I_ao, I_awgo, I_aw, Ho, Ha, Hogw, Hago, Hagow, Hagw, EU, ThreeVarRDobj
        else
            performance_df = performancemeasures2DataFrame(I_ow, I_ao, I_awgo, I_aw, Ho, Ha, Hogw, Hago, Hagow, Hagw, EU, ThreeVarRDobj)
            return po_new, pa_new, pogw, pago_new, pagow, pagw, performance_df 
        end
    end
    
end



#TODO: update module (export the new functions)

#TODO: test the special cases by setting different temperatures to certain values

#TODO: is it possible to choose in the initialization routine, whether you want Float64 or the type with
#infinite precision (BigFloat) without changing anything else in the rest of the code - if so, provide the option to
#do so!
#On the other hand, it would be sufficient to use the BigFloat only during the iterations and round
#when computing the performance measures, etc. - perhaps that's a cleaner solution


