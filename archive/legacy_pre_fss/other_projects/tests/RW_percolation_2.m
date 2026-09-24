clear
format short g

%%
L = 400;

LW = 1e5;
NW = 100;
t = (1:LW)';
p = 0:0.05:0.6;
sp = [0,0.9];
Np = numel(p);
wt = [20,5];
msd = zeros(LW,Np);
for i_p = 1:Np
    R = rand(L,L);
    
    bw = R < p(i_p);
    % i_rsp = find(bw==0);
    % [u,v] = ind2sub([L,L],find(bw));
    [px,py] = ind2sub([L,L],find(~bw));
    
    x = zeros(LW,NW); y = x;
    N_rsp = numel(px);
    rp = ceil(rand(NW,1)*N_rsp);
    rsp = [px(rp),py(rp)];
    %isp = sp(i_p)
    parfor i_rw = 1:NW
        
        [xy,xyp] = RW_P_SP(bw,LW,L,rsp(i_rw,:),wt);
%         [xy,xyp] = RW_P(bw,LW,L,rsp(i_rw,:));
        x(:,i_rw) = xy(:,1);
        y(:,i_rw) = xy(:,2);
        
    end
    
    % uv = mod([u,v]-L/2,L)+1;
    %
    dx = x - repmat(x(1,:),LW,1);
    dy = y - repmat(y(1,:),LW,1);
    sd = (dx.*dx + dy.*dy);
    
    msd(:,i_p) = mean(sd,2);
end
% figure(1);plot(xyp(:,1),xyp(:,2),'.',u,v,'ok');axis([0 L 0 L])
% figure(2);plot(x,y,'.')
figure(3);loglog(t,msd(:,:))
% % ylim([10,1e5])
%
% % pf = polyfit(t,msd(:,1),1)
%
% plot(y,'o')
%
t = t(11:end);
msd = msd(11:end,:);
%%
ln_t = log10(t);
ln_msd = log10(msd);
figure(3);loglog(t,msd(:,:))

t_ln = logspace(1,4.7,100)';
msd_ln = zeros(100,Np)
for i_p = 1:Np
    
    pf = polyfit(ln_t,ln_msd(:,i_p),2)
%     msd_ln(:,i_p) = polyval(pf,t_ln);
    
end
% figure(4);plot(ln_t,ln_msd(:,:),'-',log10(t_ln),log10(msd_ln(:,:)),'o')
 
