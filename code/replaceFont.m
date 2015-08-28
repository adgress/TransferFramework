function [] = replaceFont()
    fig = gcf;
    fontSize = 12;
    %fontName = 'Times New Roman';
    fontName = 'Helvetica';
    %set(findall(gcf,'type','text'),'FontSize',fontSize);
    set(findall(gcf,'type','text'),'FontName',fontName);
end