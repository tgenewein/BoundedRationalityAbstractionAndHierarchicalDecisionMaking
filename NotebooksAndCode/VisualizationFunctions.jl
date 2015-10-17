

#standard theme (to make plots consistent and allow for more control for publication-quality plots)
function BAtheme(;args...)
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
                #boxplot_spacing: Spacing between boxplots in Geom.boxplot. (Measure)
                ;args...
                )
end


#standard continous color scale used by visualization functions in this file
function BAcontinuouscolorscale(scalename::AbstractString)
    #you can pick your own N colors for the gradient with a specified color
    #(or an array of colors) as a seed (i.e. these colors will be included)
    #the other colors will be maximally distinguishable: search-range can be specified:
    #  lchoices - from 0-100
    #  cchoices - from 0-100
    #  hchoices - from 0-360
    #-----------------------
    #colors = distinguishable_colors(2,[color("darkblue"),color("white")],
    #lchoices = linspace(0, 100, 15),cchoices = linspace(0, 100, 15),hchoices = linspace(0, 360, 20))


    #alternatively, use a built-in colormap; they have been designed (scientifically) for
    #most accurately displaying data using a color-coding.
    colors = colormap(scalename)


    #you can transform the colors to simulate certain visual deficiencies
    #with an additional (float) parameter, you could set the strength of the deficiency (from 0.0 to 1.0)
    #colors = deuteranopic(colors) #green-deficient, most common
    #colors = protanopic(colors)   #red-deficient
    #colors = tritanopic(colors)   #blue-yellow deficiency, least common
    return Scale.lab_gradient(colors...)
end


#standard color scale for visualizing matrices)
function BAmatrixvisscale()
    return Scale.ContinuousColorScale(BAcontinuouscolorscale("Blues"))
end

#standard color scale for visualizing probabilities (i.e. values ∈ (0,1))
function BAprobabilityvisscale()
    return Scale.ContinuousColorScale(BAcontinuouscolorscale("Reds"),minvalue=0.0,maxvalue=1)
end



#standard discrete color-scale used by visualization functions in this file
function BAdiscretecolorscale(ncolors::Integer)
    return BAdiscretecolorscale(ncolors,0)
end

#standard discrete color-scale used by visualization functions in this file
#offset is the number of colors that are skipped
function BAdiscretecolorscale(ncolors::Integer, offset::Integer)
    if ncolors < 1
        error("Less than 1 colors requested - invalid operation.")
    end
    if offset < 0
        error("Offset value must be positive but negative value was provided.")
    end
    #these are the Gadfly default colors (for continuous colors)
    colors = [Scale.color_continuous().f(p) for p in linspace(0, 1, (ncolors+offset))]
    #colors = ["blue","purple"]
    navailable = size(colors,1)

    if (offset+ncolors)>navailable
        error("More colors requested than available - extend the manual color scale in BAdiscretecolorscale(...) if possible")
    else
        return Scale.color_discrete_manual(colors[(offset+1):(offset+ncolors)]...)
    end
end






#rectbin plot of p(a) (the marginal)
function visualizeBAmarginal(pa_df::DataFrame, avec::Vector; alabel="Action a", legendlabel="p*(a)", theme_args...)
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
                   Guide.xticks(label=false), Guide.xlabel(nothing, orientation=:horizontal),
                   Guide.ylabel(alabel, orientation=:vertical),
                   BAtheme(;theme_args...), BAprobabilityvisscale() )
    else
        plt = plot(pa_df, x=av, y="a", color="p_a", Geom.rectbin,
                   Scale.x_discrete, Scale.y_discrete,
                   Guide.colorkey(legendlabel),
                   Guide.xticks(label=false), Guide.xlabel(nothing, orientation=:horizontal),
                   Guide.ylabel(alabel, orientation=:vertical),
                   BAtheme(;theme_args...), BAprobabilityvisscale() )
    end

    return plt
end

#2D rectbin plot of p(a) (the marginal)
function visualizeBAmarginal(pa::Vector, avec::Vector; alabel="Action a", legendlabel="p*(a)", theme_args...)
    pa_df = BAmarginal2DataFrame(pa,avec)
    plt = visualizeBAmarginal(pa_df, avec, alabel=alabel, legendlabel=legendlabel; theme_args...)
    return plt
end

#2D rectbin plot of p(a) (the marginal)
function visualizeBAmarginal{T<:AbstractString}(pa::Vector, avec::Vector, a_strings::Vector{T};
                             alabel="Action a", legendlabel="p*(a)", theme_args...)

    pa_df = BAmarginal2DataFrame(pa,avec,a_strings)
    plt = visualizeBAmarginal(pa_df, avec, alabel=alabel, legendlabel=legendlabel; theme_args...)
    return plt
end






#2D rectbin plot of p(a|w) (the conditional)
function visualizeBAconditional(pagw_df::DataFrame, avec::Vector, wvec::Vector;
                                alabel="Action a", wlabel="World state o", legendlabel="p*(a|w)",
                                useprob_colorscale::Bool=true, theme_args...)
    #check if strings are provided (the check below is a bit ugly,
    #but there seems to be a bug/problem with [:a_sting] in names(pagw_df))
    #if either one of the strings is missing, don't use both -
    #only providing a string-representation for one variable is not provided
    use_strings = true
    if sum([:a_string].==names(pagw_df)) == 0
        use_strings = false
    end
    if sum([:w_string].==names(pagw_df)) == 0
        use_strings = false
    end

    if useprob_colorscale
        colorscale = BAprobabilityvisscale()
    else
        colorscale = BAmatrixvisscale()
    end

    #do the plotting - using a rectbin plot with discrete scales on both axes
    if(use_strings)
        plt = plot(pagw_df, x="w_string", y="a_string", color="p_agw", Geom.rectbin,
                   Scale.x_discrete, Scale.y_discrete,
                   Guide.colorkey(legendlabel),Guide.xticks(orientation=:vertical),
                   Guide.xlabel(wlabel, orientation=:horizontal), Guide.ylabel(alabel, orientation=:vertical),
                   BAtheme(;theme_args...), colorscale )
    else
        plt = plot(pagw_df, x="w", y="a", color="p_agw", Geom.rectbin,
                   Scale.x_discrete, Scale.y_discrete,
                   Guide.colorkey(legendlabel),
                   Guide.xlabel(wlabel, orientation=:horizontal), Guide.ylabel(alabel, orientation=:vertical),
                   BAtheme(;theme_args...), colorscale )
    end

    return plt
end

#2D rectbin plot of p(a|w) (the conditional)
function visualizeBAconditional(pagw::Matrix, avec::Vector, wvec::Vector;
                                alabel="Action a", wlabel="World state w", legendlabel="p*(a|w)",
                                useprob_colorscale::Bool=true, theme_args...)

    pagw_df = BAconditional2DataFrame(pagw,avec,wvec)
    plt = visualizeBAconditional(pagw_df, avec, wvec, alabel=alabel, wlabel=wlabel,
                                 legendlabel=legendlabel, useprob_colorscale=useprob_colorscale; theme_args...)
    return plt
end

#2D rectbin plot of p(a|w) (the conditional)
function visualizeBAconditional{T1<:AbstractString, T2<:AbstractString}(pagw::Matrix, avec::Vector, wvec::Vector,
                                a_strings::Vector{T1}, w_strings::Vector{T2};
                                alabel="Action a", wlabel="World state w", legendlabel="p*(a|w)",
                                useprob_colorscale::Bool=true, theme_args...)

    pagw_df = BAconditional2DataFrame(pagw,avec,wvec,a_strings,w_strings)
    plt = visualizeBAconditional(pagw_df, avec, wvec, alabel=alabel, wlabel=wlabel,
                                 legendlabel=legendlabel, useprob_colorscale=useprob_colorscale; theme_args...)
    return plt
end



#visualize arbitraty 2D matrix
function visualizeMatrix(M_xy::Matrix, xvec::Vector, yvec::Vector;
                         xlabel="x", ylabel="y", legendlabel="", theme_args...)

    return visualizeBAconditional(M_xy, yvec, xvec, alabel=ylabel, wlabel=xlabel, legendlabel=legendlabel,
                                  useprob_colorscale=false; theme_args...)
end

#visualize arbitraty 2D matrix
function visualizeMatrix{T1<:AbstractString, T2<:AbstractString}(M_xy::Matrix, xvec::Vector, yvec::Vector,
                                x_strings::Vector{T1}, y_strings::Vector{T2};
                                xlabel="x", ylabel="y", legendlabel="", theme_args...)

    return visualizeBAconditional(M_xy, yvec, xvec, y_strings, x_strings, alabel=ylabel, wlabel=xlabel,
                                 legendlabel=legendlabel, useprob_colorscale=false; theme_args...)
end






#plot a 2-dim slice of a 3-dim matrix like p(a|o,w=wk) with a dropdown box that allows to select wk
#
#legendlabelfunc is a function that takes the current w (Integer) and returns a string-representation
#for the legend - the default below simply prints "p(a|o,w=3)" in case w_vis=3 (i.e. the third entry in
#the dropdown was selected)
function visualizeBA_double_conditional(pagow, avec::Vector, ovec::Vector;
                                        alabel="Action a", olabel="Observation o",
                                        legendlabelfunc=(w)->("p*(a|o,w=$w)"),
                                        dropdownlabel = "World state w",
                                        useprob_colorscale::Bool=true, theme_args...)
    if useprob_colorscale
        colorscale = BAprobabilityvisscale()
    else
        colorscale = BAmatrixvisscale()
    end

    #create a dropdown box for selecting wk in p(a|o,w=wk)
    w_vals = [1:size(pagow,3)]  #all valid w-values

    #dropdown box for selecting w
    dropdown_w = dropdown(w_vals,label=dropdownlabel)


    #use lift to connect the actual plotting-code to the dropdown box
    plt_pagow_vis = lift(w_vis->begin
                                pagow_vis = pagow[:,:,w_vis]
                                visualizeBAconditional(pagow_vis, avec, ovec,
                                alabel=alabel, wlabel=olabel, legendlabel=legendlabelfunc(w_vis),
                                useprob_colorscale=useprob_colorscale; theme_args...)
                                end, dropdown_w)


    return dropdown_w, plt_pagow_vis

end


#plot a 2-dim slice of a 3-dim matrix like p(a|o,w=wk) with a dropdown box that allows to select wk
#
#legendlabelfunc is a function that takes the current w (Integer) and returns a string-representation
#for the legend - the default below simply prints "p(a|o,w=3)" in case w_vis=3 (i.e. the third entry in
#the dropdown was selected)
function visualizeBA_double_conditional{T1<:AbstractString, T2<:AbstractString, T3<:AbstractString}(pagow, avec::Vector, ovec::Vector,
                                        a_strings::Vector{T1}, o_strings::Vector{T2}, w_strings::Vector{T3};
                                        alabel="Action a", olabel="Observation o",
                                        legendlabelfunc=(w)->("p*(a|o,w=$w)"),
                                        dropdownlabel = "World state w",
                                        useprob_colorscale::Bool=true, theme_args...)
    if useprob_colorscale
        colorscale = BAprobabilityvisscale()
    else
        colorscale = BAmatrixvisscale()
    end

    #create a dropdown box for selecting wk in p(a|o,w=wk)
    #w_vals = [1:size(pagow,3)]  #all valid w-values

    #dropdown box for selecting w
    dropdown_w = dropdown(w_strings,label=dropdownlabel)


    #use lift to connect the actual plotting-code to the dropdown box
    plt_pagow_vis = lift(w_vis->begin
                                w_index = find(w_strings.==w_vis)[1] #use this syntax to get a scalar index,
                                                                     #otherwise it will be a 1-element array
                                pagow_vis = pagow[:,:,w_index]
                                visualizeBAconditional(pagow_vis, avec, ovec, a_strings, o_strings,
                                alabel=alabel, wlabel=olabel, legendlabel=legendlabelfunc(w_vis),
                                useprob_colorscale=useprob_colorscale; theme_args...)
                                end, dropdown_w)


    return dropdown_w, plt_pagow_vis
end







#visualization of both the marginal and the conditional
function visualizeBAsolution(pa, pagw, avec::Vector, wvec::Vector;
                             alabel="Action a", wlabel="World state w",
                             legendlabel_marginal="p*(a)", legendlabel_conditional="p*(a|w)", suppress_vis::Bool=false,
                             theme_args...)

    plt_marg = visualizeBAmarginal(pa, avec, alabel=alabel, legendlabel=legendlabel_marginal; theme_args...)
    plt_cond = visualizeBAconditional(pagw, avec, wvec, alabel=alabel, wlabel=wlabel,
                                      legendlabel=legendlabel_conditional; theme_args...)

    if suppress_vis == false
        plt_stack = hstack(plt_marg, plt_cond)
        display(plt_stack)
    end

    return plt_marg, plt_cond
end

#visualization of both the marginal and the conditional
function visualizeBAsolution{T1<:AbstractString, T2<:AbstractString}(pa::Vector, pagw::Matrix, avec::Vector, wvec::Vector,
                             a_strings::Vector{T1}, w_strings::Vector{T2};
                             alabel="Action a", wlabel="World state w",
                             legendlabel_marginal="p*(a)", legendlabel_conditional="p*(a|w)", suppress_vis::Bool=false,
                             theme_args...)

    plt_marg = visualizeBAmarginal(pa, avec, a_strings, alabel=alabel, legendlabel=legendlabel_marginal; theme_args...)
    plt_cond = visualizeBAconditional(pagw, avec, wvec, a_strings, w_strings, alabel=alabel, wlabel=wlabel,
                                      legendlabel=legendlabel_conditional; theme_args...)

    if suppress_vis == false
        plt_stack = hstack(plt_marg, plt_cond)
        display(plt_stack)
    end

    return plt_marg, plt_cond
end





#plots the different prob-distributions (this one is quite restrictive in terms of strings for labels, etc.)
function visualize_three_var_BAsolution{T1<:AbstractString, T2<:AbstractString, T3<:AbstractString}(po::Vector, pa::Vector,
                                        pogw::Matrix, pago::Matrix, pagow, pagw::Matrix,
                                        ovec::Vector, avec::Vector, wvec::Vector,
                                        o_strings::Vector{T1}, a_strings::Vector{T2}, w_strings::Vector{T3};
                                        olabel_string="o", alabel_string="a", wlabel_string="w", theme_args...)

    plt_po = visualizeBAmarginal(po, ovec, o_strings, alabel="Observation $olabel_string",
                                 legendlabel="p*($olabel_string)"; theme_args...)

    plt_pa = visualizeBAmarginal(pa, avec, a_strings, alabel="Action $alabel_string",
                                 legendlabel="p*($alabel_string)"; theme_args...)

    plt_pogw = visualizeBAconditional(pogw, ovec, wvec, o_strings, w_strings,
                                      alabel="Observation $olabel_string", wlabel="World state $wlabel_string",
                                      legendlabel="p*($olabel_string|$wlabel_string)"; theme_args...)

    plt_pago = visualizeBAconditional(pago, avec, ovec, a_strings, o_strings,
                                      alabel="Action $alabel_string", wlabel="Observation $olabel_string",
                                      legendlabel="p*($alabel_string|$olabel_string)"; theme_args...)


    plt_pagw = visualizeBAconditional(pagw, avec, wvec, a_strings, w_strings,
                                      alabel="Action $alabel_string", wlabel="World state $wlabel_string",
                                      legendlabel="p*($alabel_string|$wlabel_string)"; theme_args...)

    dpdown, plt_pagow_vis = visualizeBA_double_conditional(pagow, avec, ovec, a_strings, o_strings, w_strings,
                                                           alabel="Action $alabel_string", olabel="Observation $olabel_string",
                                                           legendlabelfunc=(w)->("p*($alabel_string|$olabel_string,$wlabel_string=$w)"),
                                                           dropdownlabel = "World state $wlabel_string"; theme_args...)

    return plt_po, plt_pa, plt_pogw, plt_pago, plt_pagw, dpdown, plt_pagow_vis

end




#plots the evolution of I(A;W), H(A), H(A|W), E[U] and the rate distortion objective as a function of β
function plotperformancemeasures(I::Vector, Ha::Vector, Hagw::Vector, EU::Vector, RDobj::Vector, β_vals::Vector;
                                 suppress_vis::Bool=false, xlabel_perf="β", theme_args...)
    #turn results into data frame
    perf_res = performancemeasures2DataFrame(I, Ha, Hagw, EU, RDobj)
    return plotperformancemeasures(perf_res, β_vals, suppress_vis = suppress_vis; theme_args...)
end

#plots the evolution of I(A;W), H(A), H(A|W), E[U] and the rate distortion objective as a function of β
function plotperformancemeasures(perf_dataframe::DataFrame, β_vals::Vector; suppress_vis::Bool=false,
                                 xlabel_perf="β", theme_args...)
    #append inv. temp. column to data frame
    perf_dataframe[:β] = β_vals

    #------- plot evolution of I(A;W), H(A), H(A|W), E[U(a,w)] and E[U(a,w)]-1/β I(A;W)
    #realign columns of data frame for easy plotting
    #(each column will become a line in the plot - values will depend on the β column)
    #entropic variables (in bits) go in one plot
    perf_res_entropic = stack(perf_dataframe, [:I_aw, :H_a, :H_agw], :β)
    #expected utility and the overall objective (in utils) go in another plot
    perf_res_utils = stack(perf_dataframe, [:E_U, :RD_obj], :β)


    #since Gadfly (currently) does not support setting the legend-strings only (colorkey strings)
    #add a column to the data-frame that has a nice string-representation of the variable-name
    nrows = size(perf_res_entropic,1)
    perf_res_entropic[:variable_str] = ["" for x in 1:nrows]
    perf_res_entropic[perf_res_entropic[:variable].==:I_aw,:variable_str] = "I(A;W)"
    perf_res_entropic[perf_res_entropic[:variable].==:H_a,:variable_str] = "H(A)"
    perf_res_entropic[perf_res_entropic[:variable].==:H_agw,:variable_str] = "H(A|W)"

    nrows = size(perf_res_utils,1)
    perf_res_utils[:variable_str] = ["" for x in 1:nrows]
    perf_res_utils[perf_res_utils[:variable].==:E_U,:variable_str] = "E[U]"
    perf_res_utils[perf_res_utils[:variable].==:RD_obj,:variable_str] = "RU_obj"

    #create the two plots
    plt_entropic = plot(perf_res_entropic,x="β",y="value",color="variable_str",Geom.line,
    BAtheme(key_position = :bottom; theme_args...), Guide.ylabel("[bits]"),Guide.colorkey(""))

    plt_utils = plot(perf_res_utils,x="β",y="value",color="variable_str",Geom.line,
    BAtheme(key_position = :bottom; theme_args...), Guide.ylabel("[utils]"),Guide.colorkey(""),BAdiscretecolorscale(2))
    #----------------------------------------------------------


    #------- plot rate-utility curve (infeasible regsion is shaded)
    nvals = size(perf_dataframe,1)
    ymax_val = maximum(perf_dataframe[:E_U])
    ymax = ones(nvals)*ymax_val
    plt_rateutility = plot(perf_dataframe,x="I_aw",y="E_U", ymin="E_U", ymax=ymax, Geom.line, Geom.ribbon,
    Guide.xlabel("I(A;W) [bits]"),Guide.ylabel("E[U]"), BAtheme(;theme_args...))
    #----------------------------------------------------------

    if suppress_vis == false
        plt_performance = vstack(plt_entropic, plt_utils) #stack plots vertically
        display(plt_performance)
        display(plt_rateutility)
    end

    return plt_entropic, plt_utils, plt_rateutility
end





#plots evolution across BA iterations (i.e. convergence)
function plot_three_var_BA_convergence(performance_df::DataFrame; suppress_vis::Bool=false,
                                       xlabel_perf="Iteration", theme_args...)
    iter = collect(1:size(performance_df,1))

    #add a column with the iteration index to the performance data frame
    performance_df[:iteration] = iter

    #------- plot evolution of I(O;W), I(A;O), I(A;W|O), I(A|W)
    #realign columns of data frame for easy plotting
    #(each column will become a line in the plot - values will depend on the iter column)
    #entropic variables (in bits) go in one plot
    perf_res_MI = stack(performance_df, [:I_ow, :I_ao, :I_awgo, :I_aw], :iteration)
    #expected utility and the overall objective (in utils) go in another plot
    perf_res_utils = stack(performance_df, [:E_U, :Objective_value], :iteration)

    #since Gadfly (currently) does not support setting the legend-strings only (colorkey strings)
    #add a column to the data-frame that has a nice string-representation of the variable-name
    nrows = size(perf_res_MI,1)
    perf_res_MI[:variable_str] = ["" for x in 1:nrows]
    perf_res_MI[perf_res_MI[:variable].==:I_ow,:variable_str] = "I(O;W)"
    perf_res_MI[perf_res_MI[:variable].==:I_ao,:variable_str] = "I(A;O)"
    perf_res_MI[perf_res_MI[:variable].==:I_awgo,:variable_str] = "I(A;W|O)"
    perf_res_MI[perf_res_MI[:variable].==:I_aw,:variable_str] = "I(A;W)"

    nrows = size(perf_res_utils,1)
    perf_res_utils[:variable_str] = ["" for x in 1:nrows]
    perf_res_utils[perf_res_utils[:variable].==:E_U,:variable_str] = "E[U]"
    perf_res_utils[perf_res_utils[:variable].==:Objective_value,:variable_str] = "Objective J"


    plot_convergence_MI = plot(perf_res_MI, x=:iteration, y="value", color="variable_str", Geom.line,
                               BAtheme(key_position = :bottom; theme_args...), Guide.ylabel("[bits]"),
                               Guide.xlabel(xlabel_perf), Guide.colorkey(""))

    plot_convergence_Util = plot(perf_res_utils, x=:iteration, y="value", color="variable_str", Geom.line,
                                 BAtheme(key_position = :bottom; theme_args...), Guide.ylabel("[utils]"),
                                 Guide.xlabel(xlabel_perf), Guide.colorkey(""), BAdiscretecolorscale(2))

    if suppress_vis == false
        plt_convergence = vstack(plot_convergence_MI, plot_convergence_Util) #stack plots vertically
        display(plt_convergence)
    end

    return plot_convergence_MI, plot_convergence_Util

end


#plots mutual informations, entropies and EU, J as (stacked) bars
function plot_three_var_performancemeasures(performance_df::DataFrame, max_utility, β1, β2, β3; theme_args...)
    #extract relevant fields in correct order from data frame
    bitval_all = [performance_df[end,:I_ow], performance_df[end,:I_ao], performance_df[end,:I_awgo], performance_df[end,:I_aw],
                  performance_df[end,:H_ogw], performance_df[end,:H_ago], performance_df[end,:H_agow], performance_df[end,:H_agw]]

    #the color values will specify the legend entries
    color_label_bitvals = ["I(O;W)", "I(A;O)", "I(A;W|O)", "I(A;W)",
                           "H(O|W)", "H(A|O)", "H(A|O,W)", "H(A|W)"]

    #the x-values are used for stacking the bars and denoting the corresponding entropic term
    x_label_bitvals = ["H(O)", "H(A)", "H(A|O)", "H(A) ",
                       "H(O)","H(A)","H(A|O)", "H(A) "]  #be careful, two of the H(A) strings have an additional space, to
                                                         #make sure that it corresponds to two different bars on the x-axis
                                                         #(though the stacked height of both bars should be equal)


    #manually set y-limits, because automatic setting fails in Gadfly when using stacked bars
    maxy = maximum(bitval_all[1:4]+bitval_all[5:end])

    #plot stacked bars for the entropic terms, that are a sum of a mutual information term and
    #a conditional term
    p_composed = plot(x=x_label_bitvals, y=bitval_all, color=color_label_bitvals, Geom.bar(position=:stack),
                      Guide.ylabel("[bits]"), Guide.xlabel(""), Guide.title("Composition of entropic terms"),
                      Guide.colorkey(""), Scale.y_continuous(minvalue=0, maxvalue=maxy), BAtheme(;theme_args...))

    subs = [1,2,3,4]
    p_MI = plot(x=color_label_bitvals[subs], y=bitval_all[subs], color=color_label_bitvals[subs], Geom.bar(),
                Guide.ylabel("[bits]"), Guide.xlabel(""), Guide.title("Mutual information terms"),
                Scale.y_continuous(minvalue=0), BAtheme(key_position = :none; theme_args...))






    #extract expected utility and value of objective and mutual information terms
    subs = [1,2,3]
    if(β3==0)
        #sequential case
        β3=eps()  #use tiny value for β3 to prevent NaN - I(A;W|O) should equal zero in the sequential case anyway
    end

    inv_betas = [1/β1, 1/β2, 1/β3]
    perf = [performance_df[end,:E_U]; bitval_all[subs] .* inv_betas; performance_df[end,:Objective_value]]

    #these labels will define the legend entries
    label_perf = ["E[U]", "1/β1 I(O;W)", "1/β2 I(A;O)", "1/β3 I(A;W|O)", "J = E[U] - 1/β ∑ I"]
    x_label_perf = ["E[U]", "E[U] ", "E[U] ", "E[U] ", "E[U] "]  #be careful, four of the entries have an additonal space,
                                                                 #to make sure that there are two stacked bars (that will
                                                                 #have the same height)


    cont_colors = [Scale.color_continuous().f(p) for p in linspace(0, 1, 2)]
    disc_colors = Scale.color_discrete_hue().f(3)
    all_colors = [cont_colors[1]; disc_colors; cont_colors[2]]
    colscale = Scale.color_discrete_manual(all_colors...)


    p_perf = plot(x=x_label_perf, y=perf, color=label_perf, Geom.bar(position=:stack),
                  Guide.ylabel("[utils]"), Guide.xlabel(""), Guide.colorkey(""),
                  Guide.title("Utility vs. processing-cost trade-off"),
                  colscale, Scale.y_continuous(minvalue=0, maxvalue=max_utility), BAtheme(;theme_args...))

    return p_MI, p_composed, p_perf
end
