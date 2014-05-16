function [ count ] = countnonemptyLines( fileName)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


    fid=fopen(fileName);
    runmore=1;
    count=0;
    while(runmore==1)
        temp = fgets(fid);        
        if (temp==-1)
            break;
        end
        temp=strtrim(temp);                        
        if (strcmp(temp, '')==1)
            continue;
        end
        count=count+1;    
    end
    fclose(fid);


end

