function [X,Y] = RW3D_P_SP(bw,LW,L,xyz0,wt)

r = ceil(rand(LW,1)*6);
Y = zeros(LW,3);
Y(1,:) = xyz0;
X = Y;

flg = 0;
spc = 0;
for ii = 2:LW
    
    xyz0 = Y(ii-1,:);
    xn = xyz0(1);    yn = xyz0(2);    zn = xyz0(3);
    xyzp0 = X(ii-1,:);
    xp = xyzp0(1);    yp = xyzp0(2);    zp = xyzp0(3);
    
    if flg == 0 
        
        switch r(ii)
            case 1
                xn = xn + 1;
                xp = xp + 1;
            case 2
                yn = yn + 1;
                yp = yp + 1;
            case 3
                zn = zn + 1;
                zp = zp + 1;
            case 4
                xn = xn - 1;
                xp = xp - 1;
            case 5
                yn = yn - 1;
                yp = yp - 1;
            case 6
                zn = zn - 1;
                zp = zp - 1;
        end
        
        xn = mod(xn-1,L) + 1;
        yn = mod(yn-1,L) + 1;
        zn = mod(zn-1,L) + 1;
        
        if bw(xn,yn,zn) == 0
            Y(ii,:) = [xn,yn,zn];
            X(ii,:) = [xp,yp,zp];
            
        else
            Y(ii,:) = xyz0;
            X(ii,:) = xyzp0;
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
        Y(ii,:) = xyz0;
        X(ii,:) = xyzp0;
    end
end

% xy = mod(xy-L/2,L)+1;

% spc

end