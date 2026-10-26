! Portable old-state Euler-Maruyama implementation of the manuscript full model.
! Run from package root: main_model.exe configs/smoke.nml
! A new CSV prefix is required; existing results are never overwritten.
program main_model
 use, intrinsic :: iso_fortran_env, only: real64,int64,compiler_version,compiler_options
 use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
 implicit none
 integer,parameter :: dp=real64
 integer :: nch=1,ntrials=2,master_seed=20261023,record_every=0
 real(dp) :: d=.1_dp,mu=3._dp,a=2.4_dp,h=1.e-4_dp,tmax=.01_dp
 real(dp) :: radius=.1_dp,perception=1._dp,ve=1._dp,r_initial=1._dp,tail_proxy=-1._dp
 character(512) :: output_prefix='results/main_smoke',config='configs/smoke.nml'
 namelist /run/ nch,ntrials,master_seed,record_every,d,mu,a,h,tmax, &
                 radius,perception,ve,r_initial,tail_proxy,output_prefix
 real(dp),allocatable :: y(:,:),v(:,:),dirs(:,:),dist(:)
 real(dp) :: x(2),noise(2),u(2),rho,angle,escape(2),speed,time,total,sumobs
 real(dp) :: pi,capmean,fullmean,hybrid,rate
 integer :: trial,j,unit_in,unit_t,unit_s,unit_c,unit_i,ios,ncap
 integer(int64) :: tick,nticks
 logical :: captured
 if(command_argument_count()>0)call get_command_argument(1,config)
 open(newunit=unit_in,file=trim(config),status='old',action='read',iostat=ios)
 if(ios/=0)error stop 'Cannot read namelist'
 read(unit_in,nml=run,iostat=ios);close(unit_in)
 if(ios/=0)error stop 'Invalid namelist'
 if(nch<1.or.ntrials<1.or.record_every<0)error stop 'Invalid counts'
 if(.not.all(ieee_is_finite([d,mu,a,h,tmax,radius,perception,ve,r_initial,tail_proxy]))) &
     error stop 'Nonfinite parameter'
 if(d<0.or.mu<=0.or.a<0.or.h<=0.or.tmax<h.or.radius<=0.or.perception<=0.or.ve<0) &
     error stop 'Invalid physical scales'
 if(r_initial<=radius.or.mu*h>=1)error stop 'Invalid initial distance or unstable step'
 nticks=nint(tmax/h,kind=int64)
 if(abs(real(nticks,dp)*h-tmax)>max(10*spacing(tmax),1.e-6_dp*h))error stop 'Tmax must lie on grid'
 allocate(y(2,nch),v(2,nch),dirs(2,nch),dist(nch))
 open(newunit=unit_t,file=trim(output_prefix)//'_trials.csv',status='new',action='write')
 open(newunit=unit_s,file=trim(output_prefix)//'_summary.csv',status='new',action='write')
 open(newunit=unit_i,file=trim(output_prefix)//'_run_info.txt',status='new',action='write')
 write(unit_i,nml=run)
 write(unit_i,'(a)') 'Compiler: '//compiler_version()
 write(unit_i,'(a)') 'Options: '//compiler_options()
 write(unit_i,'(a)') 'Old-state drifts; capture checked at grid endpoints; timeout is censoring.'
 write(unit_i,'(a)') 'Seeded new runs are not byte-identical reruns of historical unseeded batches.'
 close(unit_i)
 write(unit_t,'(a)') 'trial_id,N,D,mu,a,h,Tmax,observed_time,captured,censored'
 if(record_every>0)then
   open(newunit=unit_c,file=trim(output_prefix)//'_curves.csv',status='new',action='write')
   write(unit_c,'(a)') 'trial_id,chaser_id,t,X1,X2,Y1,Y2,V1,V2,speed,distance'
 endif
 pi=acos(-1._dp);ncap=0;total=0;sumobs=0
 do trial=1,ntrials
   call seed_path(master_seed,trial)
   x=0;v=0
   do j=1,nch
     angle=2*pi*real(j-1,dp)/real(nch,dp)
     y(:,j)=r_initial*[cos(angle),sin(angle)]
   enddo
   if(record_every>0)call curve(0._dp)
   captured=.false.
   do tick=1,nticks
     ! All directions, speeds and drifts use the state at the start of this step.
     do j=1,nch
       dirs(:,j)=x-y(:,j);dist(j)=sqrt(sum(dirs(:,j)**2))
       dirs(:,j)=dirs(:,j)/max(dist(j),1.e-12_dp)
     enddo
     escape=0
     do j=1,nch
       escape=escape+exp(-(dist(j)-radius)/perception)*dirs(:,j)
     enddo
     escape=ve*escape/real(nch,dp)
     call random_number(u);u(1)=max(u(1),tiny(1._dp))
     rho=sqrt(-2*log(u(1)));angle=2*pi*u(2)
     noise=sqrt(2*d*h)*rho*[cos(angle),sin(angle)]
     do j=1,nch
       speed=sqrt(sum(v(:,j)**2))
       y(:,j)=y(:,j)+h*speed*dirs(:,j)
       v(:,j)=v(:,j)+h*(-mu*v(:,j)+a*dirs(:,j))
     enddo
     x=x+h*escape+noise
     if(.not.all(ieee_is_finite(x)).or..not.all(ieee_is_finite(y)).or. &
        .not.all(ieee_is_finite(v)))error stop 'Nonfinite state'
     time=real(tick,dp)*h
     do j=1,nch
       dist(j)=sqrt(sum((x-y(:,j))**2))
     enddo
     captured=minval(dist)<=radius
     if(record_every>0)then
       if(mod(tick,int(record_every,int64))==0.or.captured.or.tick==nticks)call curve(time)
     endif
     if(captured)exit
   enddo
   if(captured)then
     ncap=ncap+1;total=total+time
   endif
   sumobs=sumobs+time
   write(unit_t,'(*(g0,:,","))') trial,nch,d,mu,a,h,tmax,time,merge(1,0,captured),merge(0,1,captured)
   flush(unit_t)
 enddo
 rate=real(ncap,dp)/real(ntrials,dp);capmean=-1;fullmean=-1;hybrid=-1
 if(ncap>0)capmean=total/real(ncap,dp)
 if(ncap==ntrials)fullmean=capmean
 if(tail_proxy>=0)hybrid=(total+real(ntrials-ncap,dp)*(tmax+tail_proxy))/real(ntrials,dp)
 write(unit_s,'(a)') 'N,D,mu,a,h,Tmax,n,captured,censored,capture_rate,captured_only_mean,'// &
                      'complete_mean,restricted_observation_mean,tail_proxy,hybrid_estimate'
 write(unit_s,'(*(g0,:,","))') nch,d,mu,a,h,tmax,ntrials,ncap,ntrials-ncap,rate, &
    capmean,fullmean,sumobs/real(ntrials,dp),tail_proxy,hybrid
 close(unit_t);close(unit_s)
 if(record_every>0)close(unit_c)
 print *, 'Completed ',ntrials,' trials. Captured: ',ncap,' Prefix: ',trim(output_prefix)
 print *, 'A value of -1 in a mean/proxy field denotes not available, never a negative time.'
contains
 subroutine seed_path(master,id)
   integer,intent(in)::master,id
   integer::count,k
   integer,allocatable::seed(:)
   integer(int64)::z
   call random_seed(size=count);allocate(seed(count))
   z=modulo(int(master,int64)+13007_int64*id,2147483646_int64)+1
   do k=1,count
     z=modulo(16807_int64*z,2147483647_int64);seed(k)=int(z)
   enddo
   call random_seed(put=seed)
 end subroutine
 subroutine curve(t)
   real(dp),intent(in)::t
   integer::k
   do k=1,nch
     write(unit_c,'(*(g0,:,","))') trial,k,t,x,y(:,k),v(:,k),sqrt(sum(v(:,k)**2)), &
                                    sqrt(sum((x-y(:,k))**2))
   enddo
 end subroutine
end program
