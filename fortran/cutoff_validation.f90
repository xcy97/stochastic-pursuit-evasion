! New, independent validation ensembles. Historical Figure 6 data are not overwritten.
! Old-state Euler-Maruyama full model; endpoint capture; independent future after cutoff.
program cutoff_validation
 use, intrinsic :: iso_fortran_env, only: real64,int64,compiler_version,compiler_options
 use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
 implicit none
 integer,parameter::dp=real64,nb=4096
 integer::nch=1,ntrials=20,first_id=1,master_seed=20261028,model=0
 real(dp)::d=.004642_dp,mu=3._dp,a=2.4_dp,h=1.e-4_dp,cutoff=1000._dp,horizon=100000._dp
 real(dp)::radius=.1_dp,perception=1._dp,ve=1._dp,r_initial=1._dp
 character(512)::prefix='pilot',config
 namelist /run/ nch,ntrials,first_id,master_seed,model,d,mu,a,h,cutoff,horizon,radius,perception,ve,r_initial,prefix
 real(dp),allocatable::y(:,:),v(:,:)
 real(dp)::x(2),dx,dy,r,ux,uy,speed,ex,ey,nscale,pi,t,tc,obs,elapsed,st,et
 real(dp)::uu(2,nb),zz(2,nb),rho,angle
 integer::i,j,k,id,ut,us,ui,ns,ios,ngi,cap0,capend,phase,idx
 integer,allocatable::saved_seed(:)
 integer(int64)::tick,ncut,nhor
 logical::captured,survivor
 call get_command_argument(1,config)
 open(newunit=ui,file=trim(config),status='old');read(ui,nml=run);close(ui)
 if(nch<1.or.ntrials<1.or.h<=0.or.cutoff<=0.or.horizon<cutoff)error stop 'Invalid run'
 if(mu*h>=1.or.d<0.or.model<0.or.model>1)error stop 'Invalid model or scales'
 ncut=nint(cutoff/h,kind=int64);nhor=nint(horizon/h,kind=int64)
 if(abs(ncut*h-cutoff)>1.e-8_dp.or.abs(nhor*h-horizon)>1.e-8_dp)error stop 'Off-grid times'
 allocate(y(2,nch),v(2,nch));call random_seed(size=ns);allocate(saved_seed(ns))
 open(newunit=ut,file=trim(prefix)//'_trials.csv',status='new')
 open(newunit=us,file=trim(prefix)//'_cutoff_states.csv',status='new')
 open(newunit=ui,file=trim(prefix)//'_info.txt',status='new')
 write(ui,nml=run)
 write(ui,'(a)') 'Compiler '//compiler_version()
 write(ui,'(a)') 'Options '//compiler_options()
 write(ui,'(a)') 'model=0 full model A; model=1 aligned constant-speed model C control'
 write(ui,'(a)') 'Independent future seed domain after cutoff. No resetting of positions or internal states.'
 close(ui)
 write(ut,'(a)') 'trial_id,N,D,model,h,cutoff,horizon,observed_time,captured_by_cutoff,captured_by_horizon,remaining_observed'
 write(us,'(a)') 'trial_id,chaser_id,X1,X2,Y1,Y2,V1,V2,distance,speed'
 pi=acos(-1._dp);nscale=sqrt(2*d*h);cap0=0;capend=0
 call cpu_time(st)
 do id=first_id,first_id+ntrials-1
  call seed_path(id,0);idx=nb+1;x=0;v=0
  do j=1,nch
   angle=2*pi*(j-1)/real(nch,dp);y(:,j)=r_initial*[cos(angle),sin(angle)]
  enddo
  captured=.false.;survivor=.false.;phase=0
  do tick=1,nhor
   if(idx>nb)then
    call random_number(uu)
    do k=1,nb
     rho=sqrt(-2*log(max(uu(1,k),tiny(1._dp))));angle=2*pi*uu(2,k)
     zz(:,k)=rho*[cos(angle),sin(angle)]
    enddo
    idx=1
   endif
   ex=0;ey=0
   do j=1,nch
    dx=x(1)-y(1,j);dy=x(2)-y(2,j);r=sqrt(dx*dx+dy*dy)
    ux=dx/r;uy=dy/r
    ex=ex+exp(-(r-radius)/perception)*ux
    ey=ey+exp(-(r-radius)/perception)*uy
    if(model==0)then
     speed=sqrt(v(1,j)**2+v(2,j)**2)
    else
     speed=a/mu
    endif
    y(1,j)=y(1,j)+h*speed*ux;y(2,j)=y(2,j)+h*speed*uy
    v(1,j)=v(1,j)+h*(-mu*v(1,j)+a*ux)
    v(2,j)=v(2,j)+h*(-mu*v(2,j)+a*uy)
   enddo
   x(1)=x(1)+h*ve*ex/real(nch,dp)+nscale*zz(1,idx)
   x(2)=x(2)+h*ve*ey/real(nch,dp)+nscale*zz(2,idx)
   idx=idx+1
   do j=1,nch
    if(sum((x-y(:,j))**2)<=radius*radius)then
     captured=.true.;exit
    endif
   enddo
   if(captured)exit
   if(tick==ncut)then
    survivor=.true.
    do j=1,nch
     write(us,'(*(g0,:,","))')id,j,x,y(:,j),v(:,j),sqrt(sum((x-y(:,j))**2)),sqrt(sum(v(:,j)**2))
    enddo
    flush(us)
    ! New independent future has the same conditional process law and is restartable from saved state.
    call seed_path(id,1);idx=nb+1;phase=1
   endif
  enddo
  t=real(min(tick,nhor),dp)*h
  if(.not.all(ieee_is_finite(x)).or..not.all(ieee_is_finite(y)).or..not.all(ieee_is_finite(v)))error stop 'Nonfinite'
  if(captured.and.tick<=ncut)cap0=cap0+1
  if(captured)capend=capend+1
  elapsed=max(0._dp,t-cutoff)
  write(ut,'(*(g0,:,","))')id,nch,d,model,h,cutoff,horizon,t,merge(1,0,captured.and.tick<=ncut), &
    merge(1,0,captured),elapsed
  flush(ut)
 enddo
 close(ut);close(us);call cpu_time(et)
 print *, 'FINISHED ',trim(prefix),' trials=',ntrials,' captured_cutoff=',cap0,' captured_horizon=',capend,' CPU_s=',et-st
 contains
 subroutine seed_path(trial,domain)
 integer,intent(in)::trial,domain
 integer::l
 integer(int64)::z
 z=modulo(int(master_seed,int64)+104729_int64*nch+13007_int64*trial+ &
   1000000007_int64*domain+97531_int64*model,2147483646_int64)+1
 do l=1,ns
  z=modulo(16807_int64*z,2147483647_int64);saved_seed(l)=int(z)
 enddo
 call random_seed(put=saved_seed)
 end subroutine
end program
