function [] = exampleLearningCurve()    
               
    
    
    
    x = 1:20;
    yy = spline([1 5 10 15 20],[.5 .2 .25 .3 .4],x);    
    
    fontSize = 14;
    plot(x(1:end-2),yy(1:end-2));
    h_legend = legend('Estimated Error (Lower is Better)');
    set(h_legend,'FontSize',fontSize);
    xlabel('Number of Active Learning Iterations','FontSize',fontSize);
    ylabel('Error','FontSize',fontSize);    
    h_title = title('Example CV Error Estimate Curve in Active Learning');
    set(h_title,'FontSize',fontSize);
    axis([0 max(x+1) 0 .6]);
end