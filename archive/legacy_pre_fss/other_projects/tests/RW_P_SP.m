function [X,Y] = RW_P_SP(bw,LW,L,xy0,wt)



r = ceil(rand(LW,1)*4);
Y = zeros(LW,2);
Y(1,:) = xy0;
X = Y;

flg = 0;
spc = 0;
for ii = 2:LW
    
    
    xy0 = Y(ii-1,:);
    xn = xy0(1);    yn = xy0(2);
    xyp0 = X(ii-1,:);
    xp = xyp0(1);    yp = xyp0(2);
    
    if flg == 0 
        
        switch r(ii)
            case 1
                xn = xn + 1;
                xp = xp + 1;
            case 2
                yn = yn + 1;
                yp = yp + 1;
            case 3
                xn = xn - 1;
                xp = xp - 1;
            case 4
                yn = yn - 1;
                yp = yp - 1;
        end
        
        xn = mod(xn-1,L) + 1;
        yn = mod(yn-1,L) + 1;
        
        if bw(xn,yn) == 0
            Y(ii,:) = [xn,yn];
            X(ii,:) = [xp,yp];
            
        else
            Y(ii,:) = xy0;
            X(ii,:) = xyp0;
            flg = 1;
            spc = spc + 1;
            WT = ceil(abs(normrnd(wt(1),wt(2))));
        end
        
    else
         spc = spc + 1;
        if spc > WT
            flg = 0;
            spc = 0;
        end
        Y(ii,:) = xy0;
        X(ii,:) = xyp0;
    end
end


% xy = mod(xy-L/2,L)+1;

% spc


end