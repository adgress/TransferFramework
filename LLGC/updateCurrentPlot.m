%For Transfer performance plots
%{
set(findall(gcf,'type','text'),'FontSize',20);
set(legend,'Location','south');
%}
%For data set weight plots
%{
fontSize = 25;
subplot(1,5,1)
ylabel('Weight');
set(findall(gcf,'type','text'),'FontSize',fontSize);
subplot(1,5,3)
xlabel('Data Set Index');
set(findall(gcf,'type','text'),'FontSize',fontSize);
%}

%For Accuracy-with-label-noise plots
%{
title('Label Noise: 55%');
set(findall(gcf,'type','text'),'FontSize',25);
set(legend,'Location','south');
a(3) = .2;
a(4) = 1;
axis(a);
%}

%For label noise prediction plots

%title('Label Noise: 25%');
set(findall(gcf,'type','text'),'FontSize',20);

p = get(gcf,'position');
p(3:4) = [600 500];
set(gcf,'position',p);
%print -djpeg 'LLGC/paper figures/weights025.jpg' -r300%}
