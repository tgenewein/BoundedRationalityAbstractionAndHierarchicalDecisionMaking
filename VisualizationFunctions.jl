######################################################################
#This is part of the module BlahutArimoto
######################################################################

using Gadfly, DataFrames 

#import ...

export  boltzmannresult2DataFrame, BAresult2DataFrame



function boltzmannresult2DataFrame(pa::Vector, avec::Vector, varargin...)
    #if string representation for a is provided, check their dimensionality and use it
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
        pa_df = DataFrame(pa = pa, a = avec, a_string = astring)  
    else
        pa_df = DataFrame(pa = pa, a = avec)   
    end
    
    return pa_df    
end





#the function assumes that pagω has one row per a-value and one column per ω-value
function BAresult2DataFrame(pa::Vector, pagω::Matrix, avec::Vector, ωvec::Vector,varargin...)    
    #if string representations for a and ω are provided, check their dimensionality and use them
    #otherwise do not include them into the data-frames
    strings_used = true;
    nargin = length(varargin)
    if nargin == 0
        strings_used = false;
    elseif nargin == 2
        #check size (size of astring will be checked in boltmannresult2DataFrame)
        astring = varargin[1]
        ωstring = varargin[2]
        if length(ωstring) != size(pagω,2)
            error("String representation for ω and value-matrix for pagω mismatch in size.")
        end
    else
        error("Wrong number of arguments. Either provide string-representations for both a AND ω or for neither of them.")
    end
    
    
    #map matrix onto a vector
    na = size(pagω,1)
    nω = size(pagω,2)
    pagω_v = vec(pagω) #conversion using column-major convention (columns-wise)
    avec_v = vec(repmat(avec,1,nω))
    ωvec_v = vec(repmat(ωvec',na,1))
    if strings_used
        astring_v = vec(repmat(astring,1,nω))
        ωstring_v = vec(repmat(ωstring',na,1))
    end
       
    
    #fill data frames
    if strings_used
        pa_df = boltzmannresult2DataFrame(pa, avec, astring)
        pagω_df = DataFrame(pagω = pagω_v, a = avec_v, ω = ωvec_v, a_string = astring_v, ω_string = ωstring_v)    
    else
        pa_df = boltzmannresult2DataFrame(pa, avec)
        pagω_df = DataFrame(pagω = pagω_v, a = avec_v, ω = ωvec_v)    
    end
    
    
    return pa_df, pagω_df
end
