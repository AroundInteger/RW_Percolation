clear
format short g

%%
L = 500;  % Reduced for 3D to avoid memory issues
L3 = L*L*L;
LW = 1e5;  % 100,000 steps
NW = 100;
t = (1:LW)';
p = [0, 0.3116, 0.6884, 0.75];
sp = 0;
Np = numel(p);
wt = [20,5];
msd = zeros(LW,Np);

% Initialize base template for p = 0
base_template = zeros(L,L,L);

for i_p = 1:Np
    R = rand(L,L,L);  % 3D random array
    
    if i_p == 1
        % p = 0: no occupied sites
        bw = base_template;
    else
        % For higher p-values: start with previous template and add more sites
        if i_p == 2
            % p = 0.3116: start with p = 0 template, add 31.16% more sites
            additional_sites = R < p(i_p);
            bw = base_template | additional_sites;
        elseif i_p == 3
            % p = 0.6884: need to achieve 68.84% total occupation
            % Current occupation from previous template
            current_occupied = sum(base_template(:));
            target_occupied = round(p(i_p) * L3);
            additional_needed = target_occupied - current_occupied;
            
            if additional_needed > 0
                % Find unoccupied sites
                unoccupied = ~base_template;
                [unoccupied_x, unoccupied_y, unoccupied_z] = ind2sub([L,L,L], find(unoccupied));
                
                % Randomly select additional_needed sites from unoccupied ones
                if length(unoccupied_x) >= additional_needed
                    selected_indices = randperm(length(unoccupied_x), additional_needed);
                    
                    % Create new template
                    bw = base_template;
                    for idx = 1:length(selected_indices)
                        x = unoccupied_x(selected_indices(idx));
                        y = unoccupied_y(selected_indices(idx));
                        z = unoccupied_z(selected_indices(idx));
                        bw(x, y, z) = 1;
                    end
                else
                    bw = base_template;
                end
            else
                bw = base_template;
            end
                
        elseif i_p == 4
            % p = 0.75: need to achieve 75% total occupation
            current_occupied = sum(base_template(:));
            target_occupied = round(p(i_p) * L3);
            additional_needed = target_occupied - current_occupied;
            
            if additional_needed > 0
                % Find unoccupied sites
                unoccupied = ~base_template;
                [unoccupied_x, unoccupied_y, unoccupied_z] = ind2sub([L,L,L], find(unoccupied));
                
                % Randomly select additional_needed sites from unoccupied ones
                if length(unoccupied_x) >= additional_needed
                    selected_indices = randperm(length(unoccupied_x), additional_needed);
                    
                    % Create new template
                    bw = base_template;
                    for idx = 1:length(selected_indices)
                        x = unoccupied_x(selected_indices(idx));
                        y = unoccupied_y(selected_indices(idx));
                        z = unoccupied_z(selected_indices(idx));
                        bw(x, y, z) = 1;
                    end
                else
                    bw = base_template;
                end
            else
                bw = base_template;
            end
        end
        
        % Update base template for next iteration
        base_template = bw;
    end
    
    % Find free positions in 3D
    [px,py,pz] = ind2sub([L,L,L],find(~bw));
    
    % Display actual p-value
    actual_p = 1-length(px)/L3;
    fprintf('p = %.4f: actual occupation = %.4f (target = %.4f)\n', p(i_p), actual_p, p(i_p));
    
    x = zeros(LW,NW); y = x; z = x;  % Add z coordinate
    N_rsp = numel(px);
    rp = ceil(rand(NW,1)*N_rsp);
    rsp = [px(rp),py(rp),pz(rp)];  % 3D starting positions
    %isp = sp(i_p)
    parfor i_rw = 1:NW
        
        [xyz,xyzp] = RW3D_P_SP(bw,LW,L,rsp(i_rw,:),wt);
        x(:,i_rw) = xyz(:,1);
        y(:,i_rw) = xyz(:,2);
        z(:,i_rw) = xyz(:,3);  % Add z coordinate
        
    end
    
    % Calculate MSD in 3D
    dx = x - repmat(x(1,:),LW,1);
    dy = y - repmat(y(1,:),LW,1);
    dz = z - repmat(z(1,:),LW,1);  % Add z displacement
    sd = (dx.*dx + dy.*dy + dz.*dz);  % 3D MSD
    
    msd(:,i_p) = mean(sd,2);
end
% figure(1);plot3(xyzp(:,1),xyzp(:,2),xyzp(:,3),'.',px,py,pz,'ok');axis([0 L 0 L 0 L])
% figure(2);plot3(x,y,z,'.')
figure(3);loglog(t,msd(:,:))
% % ylim([10,1e5])
%
% % pf = polyfit(t,msd(:,1),1)
%
% plot(y,'o')
%
% t = t(11:end);
% msd = msd(11:end,:);
%%
% ln_t = log10(t);
% ln_msd = log10(msd);
% figure(3);loglog(t,msd(:,:))
%
% t_ln = logspace(1,4.7,100)';
% msd_ln = zeros(100,Np)
% for i_p = 1:Np
%
%     pf = polyfit(ln_t,ln_msd(:,i_p),2)
% %     msd_ln(:,i_p) = polyval(pf,t_ln);
%
% end
% % figure(4);plot(ln_t,ln_msd(:,:),'-',log10(t_ln),log10(msd_ln(:,:)),'o')
 
