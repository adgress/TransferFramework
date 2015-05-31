function [] = settablewidth(t,newWidth)
    jscroll=findjobj(t);
    rowHeaderViewport=jscroll.getComponent(4);
    rowHeader=rowHeaderViewport.getComponent(0);
    %height=rowHeader.getSize;
    %rowHeader.setSize(80,360)

    %resize the row header
    %newWidth=100 %100 pixels.
    rowHeaderViewport.setPreferredSize(java.awt.Dimension(newWidth,0));
    height=rowHeader.getHeight;
    rowHeader.setPreferredSize(java.awt.Dimension(newWidth,height));
    rowHeader.setSize(newWidth,height);
end