
function boltzmannresult2DataFrame(pa::Vector, avec::Vector, varargin...)
    #if string representation for a is provided, check its dimensionality and use it
    #otherwise do not include them into the data-frame
    strings_used = true;
    nargin = length(varargin)
    if nargin == 0
        strings_used = false;
    elseif nargin == 1
        #check size
        astring = varargin[1]
        if length(astring) != length(pa)
            error("String representation and value-vector for a have different lengths.")
        end
    else
        error("Wrong number of arguments. Only one optional argument allowed (vector with a string-representation of a).")
    end
    
    
    #fill data frame
    if strings_used
        pa_df = DataFrame(p_a=pa, a=avec, a_string=astring)  
    else
        pa_df = DataFrame(p_a=pa, a=avec)   
    end
    
    return pa_df    
end



function BAmarginal2DataFrame(pa::Vector, avec::Vector, varagin...)
    return boltzmannresult2DataFrame(pa, avec, varagin...)  
end



#the function assumes that pago has one row per a-value and one column per o-value
function BAconditional2DataFrame(pago::Matrix, avec::Vector, ovec::Vector, varargin...)  
    #if string representations for a and o are provided, check their dimensionality and use them
    #otherwise do not include them into the data-frames
    strings_used = true;
    nargin = length(varargin)
    if nargin == 0
        strings_used = false;
    elseif nargin == 2
        #check size (size of astring will be checked in boltmannresult2DataFrame)
        astring = varargin[1]
        ostring = varargin[2]
        if length(astring) != size(pago,1)
            error("String representation for a and value-matrix for pago mismatch in size.")
        end
        if length(ostring) != size(pago,2)
            error("String representation for o and value-matrix for pago mismatch in size.")
        end        
    else
        error("Wrong number of arguments. Either provide string-representations for both a AND o or for neither of them.")
    end
    
    
    #map matrix onto a vector
    na = size(pago,1)
    no = size(pago,2)
    pago_v = vec(pago) #conversion using column-major convention (columns-wise)
    avec_v = vec(repmat(avec,1,no))
    ovec_v = vec(repmat(ovec',na,1))
    if strings_used
        astring_v = vec(repmat(astring,1,no))
        ostring_v = vec(repmat(ostring',na,1))
    end
       
    
    #fill data frames
    if strings_used
        pago_df = DataFrame(p_ago=pago_v, a=avec_v, o=ovec_v, a_string=astring_v, o_string=ostring_v)    
    else
        pago_df = DataFrame(p_ago=pago_v, a=avec_v, o=ovec_v)    
    end
    
    
    return pago_df
end


#the function assumes that pago has one row per a-value and one column per o-value
function BAresult2DataFrame(pa::Vector, pago::Matrix, avec::Vector, ovec::Vector, varargin...) 
    nargin = length(varargin)
    if nargin > 0
        pa_df = BAmarginal2DataFrame(pa,avec,varargin[1])
    else
        pa_df = BAmarginal2DataFrame(pa,avec)
    end

    if nargin > 1
        pago_df = BAconditional2DataFrame(pago,avec,ovec,varargin...)
    else
        pago_df = BAconditional2DataFrame(pago,avec,ovec)
    end

    return pa_df, pago_df
end

#convert performance measures to DataFrame representation
function performancemeasures2DataFrame(I, Ha, Hago, EU, RDobj)
    return DataFrame(I_ao=I, H_a=Ha, H_ago = Hago, E_U = EU, RD_obj = RDobj)
end


#convert performance measures to DataFrame - this method is intended for the three-variable general case
function performancemeasures2DataFrame(I_ow, I_ao, I_awgo, Ho, Ha, Hogw, Hago, Hagow, EU, ThreeVarRDobj)
    return DataFrame(I_ow=I_ow, I_ao=I_ao, I_awgo=I_awgo, H_o=Ho, H_a=Ha, H_ogw=Hogw, 
                     H_ago=Hago, H_agow=Hagow, E_U=EU, Objective_value=ThreeVarRDobj)
end