function y = diffuse(y,dt,runtime,sat_thresh)

    if runtime == 0
        return
    end

    alpha = 1; % thermal diffusivity
    
    sat_lim = sat_thresh*max(y);
    
    is_sat = [0 0]; % is saturated
    
    if y(1)>sat_lim
        is_sat(1) = 1;
    end
    if y(end)>sat_lim
        is_sat(2) = 1;
    end
    
%     is_sat
    
    for t = 0 : dt : runtime
        
        a = diff(y);
        a = [a(1) a];
        if is_sat(1)
            a(1) = 0;
        end
        if is_sat(2)
            a(end) = 0;
        end
        
        a = diff(a);
        a = [a a(end)];
        if ~is_sat(1)
            a(1) = 0;
        end
        if ~is_sat(2)
            a(end) = 0;
        end

        y = y + alpha*a*dt;
        
    end
    
    if is_sat(1)
        y(1) = y(2);
    end
    if is_sat(2)
        y(end) = y(end-1);
    end
    
%     %% Spline squelch
%     
%     if squelch_len > 5
%     
%         len  = length(y);
%         pind = [len-squelch_len+1, len];
% 
%         patch1 = spline([1,squelch_len],[0 0 y(squelch_len) y(squelch_len)-y(squelch_len-1)],1:squelch_len);
%         patch2 = spline(pind,[y(pind(1)+1)-y(pind(1)) y(pind(1)) 0 0],pind(1):pind(2));
%         y(1:squelch_len)            = patch1;
%         y(pind(1):pind(2))  = patch2;
%     
%     end

end