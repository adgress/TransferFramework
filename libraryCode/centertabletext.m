function [] = centertabletext(table)
    %Code from http://www.mathworks.com/matlabcentral/newsreader/view_thread/309271
    jscrollpane = findjobj(table);
    jTable = jscrollpane.getViewport.getView;

    cellStyle = jTable.getCellStyleAt(0,0);
    cellStyle.setHorizontalAlignment(cellStyle.CENTER);

    % Table must be redrawn for the change to take affect
    jTable.repaint;
end