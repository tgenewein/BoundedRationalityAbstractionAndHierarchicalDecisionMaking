
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



#the function assumes that pago has one row per a-value and one column per w-value
function BAconditional2DataFrame(pagw::Matrix, avec::Vector, wvec::Vector, varargin...)  
    #if string representations for a and w are provided, check their dimensionality and use them
    #otherwise do not include them into the data-frames
    strings_used = true;
    nargin = length(varargin)
    if nargin == 0
        strings_used = false;
    elseif nargin == 2
        #check size (size of astring will be checked in boltmannresult2DataFrame)
        astring = varargin[1]
        wstring = varargin[2]
        if length(astring) != size(pagw,1)
            error("String representation for a and value-matrix for pagw mismatch in size.")
        end
        if length(wstring) != size(pagw,2)
            error("String representation for w and value-matrix for pagw mismatch in size.")
        end        
    else
        error("Wrong number of arguments. Either provide string-representations for both a AND w or for neither of them.")
    end
    
    
    #map matrix onto a vector
    na = size(pagw,1)
    nw = size(pagw,2)
    pagw_v = vec(pagw) #conversion using column-major convention (column-wise)
    avec_v = vec(repmat(avec,1,nw))
    wvec_v = vec(repmat(wvec',na,1))
    if strings_used
        astring_v = vec(repmat(astring,1,nw))
        wstring_v = vec(repmat(wstring',na,1))
    end
       
    
    #fill data frames
    if strings_used
        pagw_df = DataFrame(p_agw=pagw_v, a=avec_v, w=wvec_v, a_string=astring_v, w_string=wstring_v)    
    else
        pagw_df = DataFrame(p_agw=pagw_v, a=avec_v, w=wvec_v)    
    end
    
    
    return pagw_df
end


#the function assumes that pago has one row per a-value and one column per o-value
function BAresult2DataFrame(pa::Vector, pagw::Matrix, avec::Vector, wvec::Vector, varargin...) 
    nargin = length(varargin)
    if nargin > 0
        pa_df = BAmarginal2DataFrame(pa,avec,varargin[1])
    else
        pa_df = BAmarginal2DataFrame(pa,avec)
    end

    if nargin > 1
        pagw_df = BAconditional2DataFrame(pagw,avec,wvec,varargin...)
    else
        pagw_df = BAconditional2DataFrame(pagw,avec,wvec)
    end

    return pa_df, pagw_df
end

#convert performance measures to DataFrame representation
function performancemeasures2DataFrame(I, Ha, Hagw, EU, RDobj)
    return DataFrame(I_aw=I, H_a=Ha, H_agw = Hagw, E_U = EU, RD_obj = RDobj)
end


#convert performance measures to DataFrame - this method is intended for the three-variable general case
function performancemeasures2DataFrame(I_ow, I_ao, I_awgo, I_aw, Ho, Ha, Hogw, Hago, Hagow, Hagw, EU, ThreeVarRDobj)
    return DataFrame(I_ow=I_ow, I_ao=I_ao, I_awgo=I_awgo, I_aw=I_aw, H_o=Ho, H_a=Ha, H_ogw=Hogw, 
                     H_ago=Hago, H_agow=Hagow, H_agw=Hagw, E_U=EU, Objective_value=ThreeVarRDobj)
end