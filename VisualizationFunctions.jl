######################################################################
#This is part of the module BlahutArimoto
######################################################################


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



#standard theme (to make plots consistent and allow for more control for publication-quality plots)
function BATheme()
    #font = "'PT Sans','Helvetica Neue','Helvetica',sans-serif"
    #font = "Computer Modern Math"
    font = "'Latin Modern Math','Latin-Modern',serif"
    #font = "Latin Modern"
    #font = "Helvetica"
    #font = "Times New Roman"
    return Theme(line_width = 2pt,# Width of lines in the line geometry. (Measure)
                minor_label_font = font,#: Font used for minor labels such as guide entries and labels. (String)
                #minor_label_font_size: Font size used for minor labels. (Measure)
                major_label_font = font,# Font used for major labels such as titles and axis labels. (String)
                major_label_font_size = 12pt,# Font size used for major labels. (Measure)
                key_title_font = font,# Font used for titles of keys. (String)
                key_title_font_size = 11pt, # Font size used for key titles. (Measure)
                key_label_font = font,# Font used for key entry labels. (String)
                key_label_font_size = 10pt,# Font size used for key entry labels. (Measure)
                bar_spacing = 1pt,# Spacing between bars in Geom.bar. (Measure)
                )
end


#standard continous color scale used by visualization functions in this file
function BAcontinuouscolorscale()
    #you can pick your own N colors for the gradient with a specified color
    #(or an array of colors) as a seed (i.e. these colors will be included)
    #the other colors will be maximally distinguishable: search-range can be specified:
    #  lchoices - from 0-100
    #  cchoices - from 0-100
    #  hchoices - from 0-360
    #-----------------------
    #colors = distinguishable_colors(3,[color("darkblue")],
    #lchoices = linspace(0, 100, 15),cchoices = linspace(0, 100, 15),hchoices = linspace(0, 360, 20))
    
    
    #alternatively, use a built-in colormap; they have been designed (scientifically) for 
    #most accurately displaying data using a color-coding.
    colors = colormap("Blues")
    
    
    #you can transform the colors to simulate certain visual deficiencies
    #with an additional (float) parameter, you could set the strength of the deficiency (from 0.0 to 1.0)
    #colors = deuteranopic(colors) #green-deficient, most common
    #colors = protanopic(colors)   #red-deficient
    #colors = tritanopic(colors)   #blue-yellow deficiency, least common
    return Scale.lab_gradient(colors...)
end


#standard color scale for visualizing probabilities (i.e. values ∈ (0,1))
function BAprobabilityvisscale()
    return Scale.ContinuousColorScale(BAcontinuouscolorscale(),minvalue=0.0,maxvalue=1)
end





#rectbin plot of p(a) (the marginal)
function visualizeBAmarginal(pa_df::DataFrame, avec::Vector; alabel="Action a", legendlabel="p(a)")
    #check if strings are provided (the check below is a bit ugly, 
    #but there seems to be a bug/problem with [:a_sting] in names(pa_df))
    use_strings = true
    if sum([:a_string].==names(pa_df)) == 0
        use_strings = false
    end
    
    #do the plotting - using a rectbin plot with discrete scales on both axes
    av = vec(zeros(size(pa_df,1),1))
    if(use_strings)
        plt = plot(pa_df, x=av, y="a_string", color="p_a", Geom.rectbin,
                   Scale.x_discrete, Scale.y_discrete,
                   Guide.colorkey(legendlabel),
                   Guide.xticks(label=false), Guide.xlabel(nothing),
                   Guide.ylabel(alabel, orientation=:vertical),
                   BATheme(),
        BAprobabilityvisscale()
        )
    else
        plt = plot(pa_df, x=av, y="a", color="p_a", Geom.rectbin,
                   Scale.x_discrete, Scale.y_discrete,
                   Guide.colorkey(legendlabel),
                   Guide.xticks(label=false), Guide.xlabel(nothing),
                   Guide.ylabel(alabel, orientation=:vertical),
                   BATheme(),
        BAprobabilityvisscale()
        )
    end

    return plt
end

#2D rectbin plot of p(a) (the marginal)
function visualizeBAmarginal(pa::Vector, avec::Vector; alabel="Action a", legendlabel="p(a)")
    pa_df = BAmarginal2DataFrame(pa,avec) 
    plt = visualizeBAmarginal(pa_df, avec, alabel=alabel, legendlabel=legendlabel)
    return plt
end

#2D rectbin plot of p(a) (the marginal)
function visualizeBAmarginal{T<:String}(pa::Vector, avec::Vector, a_strings::Vector{T};
                             alabel="Action a", legendlabel="p(a)")

    pa_df = BAmarginal2DataFrame(pa,avec,a_strings) 
    plt = visualizeBAmarginal(pa_df, avec, alabel=alabel, legendlabel=legendlabel)
    return plt
end





#2D rectbin plot of p(a|o) (the conditional)
function visualizeBAconditional(pago_df::DataFrame, avec::Vector, ovec::Vector; 
                                alabel="Action a", olabel="Observation o", legendlabel="p(a|o)")
    #check if strings are provided (the check below is a bit ugly, 
    #but there seems to be a bug/problem with [:a_sting] in names(pago_df))
    #if either one of the strings is missing, don't use both - 
    #only providing a string-representation for one variable is not provided
    use_strings = true
    if sum([:a_string].==names(pago_df)) == 0
        use_strings = false
    end
    if sum([:o_string].==names(pago_df)) == 0
        use_strings = false
    end
    
    #do the plotting - using a rectbin plot with discrete scales on both axes
    if(use_strings)
        plt = plot(pago_df, x="o_string", y="a_string", color="p_ago", Geom.rectbin,
                   Scale.x_discrete, Scale.y_discrete,
                   Guide.colorkey(legendlabel),Guide.xticks(orientation=:vertical),
                   Guide.xlabel(olabel), Guide.ylabel(alabel, orientation=:vertical),
                   BATheme(),
        BAprobabilityvisscale()
        )
    else
        plt = plot(pago_df, x="o", y="a", color="p_ago", Geom.rectbin,
                   Scale.x_discrete, Scale.y_discrete,
                   Guide.colorkey(legendlabel),
                   Guide.xlabel(olabel), Guide.ylabel(alabel, orientation=:vertical),
                   BATheme(),
        BAprobabilityvisscale()
        )
    end

    return plt
end

#2D rectbin plot of p(a|o) (the conditional)
function visualizeBAconditional(pago::Matrix, avec::Vector, ovec::Vector; 
                                alabel="Action a", olabel="Observation o", legendlabel="p(a|o)")

    pago_df = BAconditional2DataFrame(pago,avec,ovec) 
    plt = visualizeBAconditional(pago_df, avec, ovec, alabel=alabel, olabel=olabel, legendlabel=legendlabel)
    return plt
end

#2D rectbin plot of p(a|o) (the conditional)
function visualizeBAconditional{T1<:String, T2<:String}(pago::Matrix, avec::Vector, ovec::Vector, 
                                a_strings::Vector{T1}, o_strings::Vector{T2}; 
                                alabel="Action a", olabel="Observation o", legendlabel="p(a|o)")

    pago_df = BAconditional2DataFrame(pago,avec,ovec,a_strings,o_strings) 
    plt = visualizeBAconditional(pago_df, avec, ovec, alabel=alabel, olabel=olabel, legendlabel=legendlabel)
    return plt
end




#visualization of both the marginal and the conditional
function visualizeBAsolution(pa, pago, avec::Vector, ovec::Vector; 
                             alabel="Action a", olabel="Observation o",
                             legendlabel_marginal="p(a)", legendlabel_conditional="p(a|o)")

    plt_marg = visualizeBAmarginal(pa, avec, alabel=alabel, legendlabel=legendlabel_marginal)
    plt_cond = visualizeBAconditional(pago, avec, ovec, alabel=alabel, olabel=olabel, legendlabel=legendlabel_conditional)

    display(plt_marg)
    display(plt_cond)
    return plt_marg, plt_cond
end

#visualization of both the marginal and the conditional
function visualizeBAsolution{T1<:String, T2<:String}(pa::Vector, pago::Matrix, avec::Vector, ovec::Vector,
                             a_strings::Vector{T1}, o_strings::Vector{T2}; 
                             alabel="Action a", olabel="Observation o",
                             legendlabel_marginal="p(a)", legendlabel_conditional="p(a|o)")

    plt_marg = visualizeBAmarginal(pa, avec, a_strings, alabel=alabel, legendlabel=legendlabel_marginal)
    plt_cond = visualizeBAconditional(pago, avec, ovec, a_strings, o_strings, alabel=alabel, olabel=olabel, legendlabel=legendlabel_conditional)

    display(plt_marg)
    display(plt_cond)
    return plt_marg, plt_cond
end



#TODO: add the option to provide a title-string to the plots?

#TODO: functions for visualizing precomputed utility and umax
#      same as visualizeBA functions with the exception that the limits of the continuous-scale are different
#      perhaps reuse the same functions but define a type (probdist) for the BAresults.
#      If the vis fcn shows a probdist, use ∈(0,1) for color-scale limits, otherwise not.
#      Check if you could reuse an existing type for this (perhaps from Distributions.jl?)

#TODO: functions for visualizing distribution-vectors as bars (similar to the FreeEnergy notebook)?