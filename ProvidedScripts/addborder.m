function [success] = addborder(hAxes,Color,Width)
%ADDBORDER Adds a border to the outside of image for reference
%   hAxes - The handle to the figure or subplot to have border added
%   Color - the color of the border to be added
%   Width - LineWidth for the border.
    
    if(isa(hAxes,'matlab.ui.Figure'))
        hAxes = hAxes.CurrentAxes;
    elseif isa(hAxes,'matlab.graphics.axis.Axes')
        % huzzah! nothing else needed
    else
        success = false;
        disp('Error in addborder: input was not valid figure or axes');
        return;
    end
    
    h = hAxes.XLim(2);
    d = hAxes.YLim(2);
    
    line([1 1],[1,d],'Color',Color,'LineWidth',Width) % left
    line([h h],[1 d],'Color',Color,'LineWidth',Width) % right
    line([1 h],[1 1],'Color',Color,'LineWidth',Width) % top
    line([1 h],[d d],'Color',Color,'LineWidth',Width) % bottom
    
    success = true;
end

