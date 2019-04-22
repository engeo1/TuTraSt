function [msd_tot,process_exec,distances,D_ave]=kmc_noplot(basis_sites,processes,ngrid,n_particle,nsteps,msd_steps,print_every,grid_size,nruns,BT,per_tunnel)abc=ngrid.*grid_size;x_lim_min=0;x_lim_max=0;y_lim_max=0;y_lim_min=0;y_max=[0 0 0];y_min=[0 0 0];x_min=[0 0 0];x_max=[0 0 0];time=0;dt=[];nbasis=length(basis_sites(:,1));nprocesses=length(processes(:,1));distances=(basis_sites(processes(:,2),1:3)-basis_sites(processes(:,1),1:3)+[ngrid(1)*processes(:,4) ngrid(2)*processes(:,5) ngrid(3)*processes(:,6)]).*grid_size(1);types=zeros(nbasis,1); for iT=1:max(basis_sites(:,4))    nbasis_iT=sum(basis_sites(:,4)==iT);    first=rem(nbasis_iT,n_particle)+find(basis_sites(:,4)==iT,1);    every=floor(nbasis_iT/n_particle);    types(first:every:first+nbasis_iT-1)=1;endif per_tunnel==1    n_particle=n_particle*iT; %n_particle per tunnel %%%Maybe change when running for multiple%%endtype_trajectory=[types [1:nbasis]' zeros(nbasis,3)];filename = 'traj.dat';fid_traj = fopen(filename, 'w');fprintf(fid_traj,'%s \n','%TIME, X, Y, Z');Li_sites=find(type_trajectory(:,1)==1);n_particle=length(Li_sites);trajectories=cell(n_particle,1);filename = 'D.dat';fid_D = fopen(filename, 'w');for n_runs=1:nruns    n_runs    for k=1:length(Li_sites)        Li_site_index=Li_sites(k);        fprintf(fid_traj,'%f %8f %8f %8f \n',time,type_trajectory(Li_site_index,3:5));        trajectories{k}(1,:)=[time type_trajectory(Li_site_index,3:5)];    end        for step=1:nsteps        if rem(step,10000)==0            disp(strcat('step nr: ',num2str(step)))        end        type1_index=find(types==1); %finds index of Li in types list        type2_index=[type1_index;find(types==0)]; %finds index of empty in types list %include single TS tunnels                %Find possible moves Li->empty site        process1_index=find(ismember(processes(:,1),type1_index)==1); %find index of process list with Li in start pos        process2_index=find(ismember(processes(process1_index,2),type2_index)==1); %find index of process list with empty in end pos        process_avail=process1_index(process2_index); %list of indexis of available processes        if sum(process_avail==0)            disp('No possible processes')        end                process_length=length(process_avail);        rate_length=sum(processes(process_avail,3));        pick_process=rand*rate_length;        process_sum=0;        for i=1:process_length            process_index=process_avail(i);            processes(process_index,3);            process_sum=process_sum+processes(process_index,3);            if process_sum>=pick_process                process_exec(step)=process_index;                break            end        end                %Make the move        types(processes(process_exec(step),1))=0; %set start position to empty        types(processes(process_exec(step),2))=1; %set end position to Li        coord_Li=find(type_trajectory(:,2)==processes(process_exec(step),1)); %find index in types list of moved Li        pos_Li=type_trajectory(coord_Li,2);        coord_empty=find(type_trajectory(:,2)==processes(process_exec(step),2));        pos_empty=type_trajectory(coord_empty,2);        type_trajectory(coord_Li,2)=pos_empty;        type_trajectory(coord_empty,2)=pos_Li;        type_trajectory(coord_Li,3:5)=type_trajectory(coord_Li,3:5)+distances(process_exec(step),:);        if abs(coord_Li-coord_empty)>0 %%not done for single TS tunnels            type_trajectory(coord_empty,3:5)=type_trajectory(coord_empty,3:5)-distances(process_exec(step),:);        end        dt=[dt log(1/rand)/rate_length];        time=time+dt(step);        if rem(step,10000)==0            disp(strcat('time[s]: ',num2str(time)))        end        for k=1:n_particle            Li_site_index=Li_sites(k);            trajectories{k}(step,:)=[time type_trajectory(Li_site_index,3:5)];            if  rem(step,print_every)==0                fprintf(fid_traj,'%s %8f %8f %8f \n',num2str(time),type_trajectory(Li_site_index,3:5));            end        end    end    fclose(fid_traj);    disp('computing msd')    msd_sum=0;    diff_t=[];    for i=1:n_particle        k=0;        for j=msd_steps%1:print_every:msd_steps            k=k+1;            diff=trajectories{i}(1+j:nsteps,:)-trajectories{i}(1:nsteps-j,:);            msd{i}(k,:)=[mean(diff(:,1)) mean((diff(:,2)).^2) mean((diff(:,3)).^2) mean((diff(:,4)).^2)];            disp(strcat('msd step: ',num2str(j)))            diff_t=[diff_t; diff(1)];        end                msd_sum=msd_sum+msd{i};    end    msd_tot=msd_sum/n_particle;    disp('printing msd.dat')    filename = strcat('msd',num2str(n_runs),'.dat');    fid_msd = fopen(filename, 'w');    for iD=1:3        istart=find(msd_tot(:,iD+1)>(abc(iD)).^2,1);        iend=find(msd_tot(:,iD+1)>4*(abc(iD)).^2,1);                if isempty(iend) || BT(iD)==0            D(iD)=0;        else            msd_fit=polyfit(msd_tot(istart:iend,1),msd_tot(istart:iend,iD+1),1);            D(iD)=0.5*msd_fit(1)*1e-16;                        x=msd_tot(istart:iend,1);            y=msd_fit(1)*x+msd_fit(2);            x_min(iD)=msd_tot(1,1);            x_max(iD)=msd_tot(iend,1);            y_min(iD)=min(msd_tot(1:iend,iD+1));            y_max(iD)=max(msd_tot(1:iend,iD+1));            if x_min(iD)>x_lim_min                x_lim_min=x_min(iD);            end            if x_max(iD)>x_lim_max                x_lim_max=x_max(iD);            end            if y_min(iD)<y_lim_min                y_lim_min=y_min(iD);            end            if y_max(iD)>y_lim_max                y_lim_max=y_max(iD);            end               end        for imsd=1:length(msd_tot)            fprintf(fid_msd,'%s \n',(num2str(msd_tot(imsd,:))));        end                end    filename = 'D_all.dat';    fid_D = fopen(filename, 'w');    D_all(n_runs,:)=D;    fprintf(fid_D,'%s \n',num2str(D_all(n_runs,:)));    msd_all{n_runs}=msd_tot;endD_ave=[mean(D_all(:,1)) std(D_all(:,1)) mean(D_all(:,2)) std(D_all(:,2)) mean(D_all(:,3)) std(D_all(:,3))];fclose(fid_msd);fclose(fid_D);end