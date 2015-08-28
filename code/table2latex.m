function [] = table2latex()
fig = gcf;
c = get(fig,'Children');
data = get(c(1),'Data');
rows = get(c(1),'RowName');
cols = get(c(1),'ColumnName');
cols = [{''} ; cols];
strs = {cell2latex(cols)};
for idx=1:length(rows)
    r = [rows(idx) data(idx,:)]; 
    strs{end+1} = cell2latex(r);
end
for idx=1:length(strs)
    display([strs{idx} '\\ \hline']);        
end
end

function [s] = cell2latex(c)
if isempty(c)
    s = '';
    return;
end
s = c{1};
for idx=2:length(c)
    s = [s ' & ' c{idx}];
end
end