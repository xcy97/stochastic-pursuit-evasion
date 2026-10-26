! Windows / Intel Fortran console application. All source text is ASCII.
! Model: the existing N=1 variable-speed pursuit-evasion model.
! Endpoint capture detection is retained at every level's OWN grid times.
! Three levels share Brownian increments, not merely a common random seed.
module stepcheck_support
    use, intrinsic :: iso_fortran_env, only: real64, int64, compiler_version, compiler_options
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    implicit none
    integer, parameter :: dp=real64, nl=3, nc=4
    real(dp), parameter :: fine_h=1.0e-6_dp, radius=0.1_dp, perception=1.0_dp, ve=1.0_dp
    real(dp), parameter :: pi=3.1415926535897932384626433832795_dp
    integer(int64), parameter :: stride(nl)=[100_int64,10_int64,1_int64]
    real(dp), parameter :: noise_cases(nc)=[10.0_dp,31.6228_dp,0.215443_dp,31.6228_dp]
    real(dp), parameter :: mu_cases(nc)=[3.0_dp,3.0_dp,3.0_dp,30.0_dp]
    real(dp), parameter :: a_cases(nc)=[2.4_dp,2.4_dp,2.4_dp,29.97_dp]
contains
    function istr(i) result(s)
        integer,intent(in) :: i
        character(32) :: s
        write(s,'(i0)') i
    end function
    function i64str(i) result(s)
        integer(int64),intent(in) :: i
        character(32) :: s
        write(s,'(i0)') i
    end function
    function rstr(x) result(s)
        real(dp),intent(in) :: x
        character(32) :: s
        write(s,'(es24.15e3)') x
        s=adjustl(s)
    end function
    real(dp) function wall_now()
        integer(int64) :: count, rate
        call system_clock(count,rate)
        wall_now=real(count,dp)/real(rate,dp)
    end function
    subroutine seed_trial(master,case_id,trial_id)
        integer,intent(in) :: master,case_id,trial_id
        integer :: n,i
        integer,allocatable :: seed(:)
        integer(int64) :: x
        call random_seed(size=n)
        allocate(seed(n))
        x=modulo(int(master,int64)+104729_int64*case_id+13007_int64*trial_id,2147483646_int64)+1
        do i=1,n
            x=modulo(16807_int64*x,2147483647_int64)
            seed(i)=int(x)
        end do
        call random_seed(put=seed)
    end subroutine
    subroutine gaussian_pair(z)
        real(dp),intent(out) :: z(2)
        real(dp) :: u(2),rho,angle
        call random_number(u)
        u(1)=max(u(1),tiny(1.0_dp))
        rho=sqrt(-2.0_dp*log(u(1)))
        angle=2.0_dp*pi*u(2)
        z=[rho*cos(angle),rho*sin(angle)]
    end subroutine
    subroutine em_step(state,h,dw,d,mu,a)
        real(dp),intent(inout) :: state(6)
        real(dp),intent(in) :: h,dw(2),d,mu,a
        real(dp) :: old(6),dx,dy,r,g,speed
        old=state
        dx=old(1)-old(3); dy=old(2)-old(4)
        r=sqrt(dx*dx+dy*dy)
        if (r>1.0e-12_dp) then
            dx=dx/r;dy=dy/r
        else
            dx=0.0_dp;dy=0.0_dp
        end if
        g=exp(-(r-radius)/perception)
        speed=sqrt(old(5)*old(5)+old(6)*old(6))
        state(1)=old(1)+ve*g*dx*h+sqrt(2.0_dp*d)*dw(1)
        state(2)=old(2)+ve*g*dy*h+sqrt(2.0_dp*d)*dw(2)
        state(3)=old(3)+speed*dx*h
        state(4)=old(4)+speed*dy*h
        state(5)=old(5)+(-mu*old(5)+a*dx)*h
        state(6)=old(6)+(-mu*old(6)+a*dy)*h
    end subroutine
    subroutine simulate_trial(d,mu,a,tmax,selected,observed,captured,updates,draws,invalid,terminal_state)
        real(dp),intent(in) :: d,mu,a,tmax
        integer,intent(in) :: selected ! 0: all levels; 1/2/3: standalone timing run
        real(dp),intent(out) :: observed(nl)
        logical,intent(out) :: captured(nl),invalid
        integer(int64),intent(out) :: updates(nl),draws
        real(dp),intent(out),optional :: terminal_state(6,nl)
        real(dp) :: state(6,nl),pending(2,nl),z(2),dw(2),r2
        integer(int64) :: tick,next_tick(nl),target,end_tick,jump,next_report
        integer :: l
        logical :: active(nl)
        state=0.0_dp;state(3,:)=1.0_dp
        pending=0.0_dp;captured=.false.;updates=0;draws=0;invalid=.false.
        observed=tmax;tick=0;end_tick=nint(tmax/fine_h,kind=int64)
        next_report=10000000_int64
        active=.true.
        if (selected/=0) then
            active=.false.;active(selected)=.true.
        end if
        next_tick=stride
        do while(any(active))
            target=minval(next_tick,mask=active)
            if(target>end_tick) exit
            jump=target-tick
            if(jump<=0) error stop 'Non-positive Brownian time increment'
            call gaussian_pair(z)
            dw=sqrt(real(jump,dp)*fine_h)*z
            draws=draws+1
            if(draws==next_report) then
                write(*,'(a,f14.6,a,3l2)') '    Within-trial time=', &
                    real(target,dp)*fine_h,' active levels:',active
                next_report=next_report+10000000_int64
            end if
            do l=1,nl
                if(active(l)) pending(:,l)=pending(:,l)+dw
            end do
            tick=target
            do l=1,nl
                if(.not.active(l)) cycle
                if(next_tick(l)/=tick) cycle
                call em_step(state(:,l),real(stride(l),dp)*fine_h,pending(:,l),d,mu,a)
                updates(l)=updates(l)+1;pending(:,l)=0.0_dp
                if(.not.all(ieee_is_finite(state(:,l)))) then
                    invalid=.true.
                    return
                end if
                r2=(state(1,l)-state(3,l))**2+(state(2,l)-state(4,l))**2
                if(r2<=radius*radius) then
                    captured(l)=.true.;observed(l)=real(tick,dp)*fine_h;active(l)=.false.
                else if(tick==end_tick) then
                    active(l)=.false.
                else
                    next_tick(l)=next_tick(l)+stride(l)
                end if
            end do
        end do
        if(present(terminal_state)) terminal_state=state
    end subroutine
    recursive subroutine quicksort(x,left,right)
        real(dp),intent(inout) :: x(:)
        integer,intent(in) :: left,right
        integer :: i,j
        real(dp) :: p,tmp
        if(left>=right) return
        p=x((left+right)/2);i=left;j=right
        do
            do while(x(i)<p)
                i=i+1
            end do
            do while(x(j)>p)
                j=j-1
            end do
            if(i<=j) then
                tmp=x(i);x(i)=x(j);x(j)=tmp;i=i+1;j=j-1
            end if
            if(i>j) exit
        end do
        if(left<j) call quicksort(x,left,j)
        if(i<right) call quicksort(x,i,right)
    end subroutine
    real(dp) function percentile(x,p)
        real(dp),intent(in) :: x(:),p
        real(dp) :: position,frac
        integer :: lo,hi
        position=1.0_dp+p*real(size(x)-1,dp)
        lo=int(floor(position));hi=min(lo+1,size(x));frac=position-real(lo,dp)
        percentile=x(lo)*(1.0_dp-frac)+x(hi)*frac
    end function
    subroutine bootstrap(x,b,mean,lo,hi,sd)
        real(dp),intent(in) :: x(:)
        integer,intent(in) :: b
        real(dp),intent(out) :: mean,lo,hi,sd
        real(dp),allocatable :: estimates(:)
        real(dp) :: u,total
        integer :: n,k,j,index
        n=size(x);mean=sum(x)/real(n,dp);sd=0.0_dp
        if(n>1) sd=sqrt(sum((x-mean)**2)/real(n-1,dp))
        allocate(estimates(b))
        do k=1,b
            total=0
            do j=1,n
                call random_number(u);index=1+int(u*n)
                total=total+x(index)
            end do
            estimates(k)=total/real(n,dp)
        end do
        call quicksort(estimates,1,b)
        lo=percentile(estimates,0.025_dp);hi=percentile(estimates,0.975_dp)
    end subroutine
    subroutine paired_bootstrap(x,y,b,delta,lo,hi,pct,pctlo,pcthi)
        real(dp),intent(in) :: x(:),y(:)
        integer,intent(in) :: b
        real(dp),intent(out) :: delta,lo,hi,pct,pctlo,pcthi
        real(dp),allocatable :: differences(:),ratios(:)
        real(dp) :: sx,sy,u
        integer :: n,k,j,index
        n=size(x);delta=sum(x-y)/real(n,dp);pct=100.0_dp*delta/(sum(y)/real(n,dp))
        allocate(differences(b),ratios(b))
        do k=1,b
            sx=0;sy=0
            do j=1,n
                call random_number(u);index=1+int(u*n)
                sx=sx+x(index);sy=sy+y(index)
            end do
            differences(k)=(sx-sy)/real(n,dp);ratios(k)=100.0_dp*(sx-sy)/sy
        end do
        call quicksort(differences,1,b);call quicksort(ratios,1,b)
        lo=percentile(differences,0.025_dp);hi=percentile(differences,0.975_dp)
        pctlo=percentile(ratios,0.025_dp);pcthi=percentile(ratios,0.975_dp)
    end subroutine
end module

program r2c2_stepcheck
    use stepcheck_support
    implicit none
    ! Defaults: 1000 independent paths per parameter case.
    ! Override with --trials=. No existing outputs are overwritten.
    integer :: ntrials=1000,master=20261023,nboot=2000,selected_case=0,selected_level=0
    real(dp) :: tmax=100000.0_dp
    character(2048) :: output_root='results',folder,display_folder,arg,cwd,cmd
    character(32) :: stamp
    integer :: values(8),i,j,l,k,case_id,ios,narg,uc,us,up,ut,ui,uw,log_every
    integer :: captured_count,comparator,pair_l(3),pair_r(3)
    real(dp) :: obs(nl),cpu0,cpu1,wall0,elapsed,cpu_elapsed,mean,lo,hi,sd,capmean
    real(dp) :: delta,dlo,dhi,pct,plo,phi
    real(dp),allocatable :: all_obs(:,:)
    logical :: cap(nl),bad
    logical,allocatable :: all_cap(:,:)
    integer(int64) :: updates(nl),draws,case_updates(nl),case_draws,end_tick
    character(64) :: quantity,mct,mctlo,mcthi,captext

    narg=command_argument_count()
    do i=1,narg
        call get_command_argument(i,arg)
        if(index(arg,'--trials=')==1) then
            read(arg(10:),*,iostat=ios) ntrials
        else if(index(arg,'--tmax=')==1) then
            read(arg(8:),*,iostat=ios) tmax
        else if(index(arg,'--seed=')==1) then
            read(arg(8:),*,iostat=ios) master
        else if(index(arg,'--case=')==1) then
            read(arg(8:),*,iostat=ios) selected_case
        else if(index(arg,'--level=')==1) then
            read(arg(9:),*,iostat=ios) selected_level
        else if(index(arg,'--bootstrap=')==1) then
            read(arg(13:),*,iostat=ios) nboot
        else if(index(arg,'--output=')==1) then
            output_root=arg(10:);ios=0
        else
            print *, 'Unknown argument: ',trim(arg)
            error stop 'Valid: --trials= --tmax= --seed= --case= --level= --bootstrap= --output='
        end if
        if(ios/=0) error stop 'Invalid command-line value'
    end do
    if(ntrials<2.or.ntrials>1000000) error stop 'Trials must be between 2 and 1000000'
    if(nboot<100) error stop 'Use at least 100 bootstrap resamples'
    do i=1,len_trim(output_root)
        if(iachar(output_root(i:i))>127) error stop 'Use an ASCII relative output name, e.g. results'
        if(output_root(i:i)=='"'.or.output_root(i:i)=='%') error stop 'Invalid output directory characters'
    end do
    if(selected_case<0.or.selected_case>nc) error stop 'Case must be 0(all) or 1..4'
    if(selected_level<0.or.selected_level>nl) error stop 'Level must be 0(all) or 1..3'
    if(.not.ieee_is_finite(tmax)) error stop 'Invalid Tmax'
    if(tmax<1.0e-4_dp.or.tmax>1.0e9_dp) error stop 'Invalid Tmax range'
    end_tick=nint(tmax/fine_h,kind=int64)
    if(modulo(end_tick,stride(1))/=0) error stop 'Tmax must be a multiple of 1e-4'
    if(abs(real(end_tick,dp)*fine_h-tmax)>1.0e-9_dp*max(1.0_dp,tmax)) error stop 'Tmax grid mismatch'
    call date_and_time(values=values)
    write(stamp,'(i4.4,2i2.2,a,3i2.2,a,i3.3)') values(1:3),'_',values(5:7),'_',values(8)
    folder=trim(output_root)//'\R2C2_run_'//trim(stamp)
    cmd='cmd /c mkdir "'//trim(folder)//'"'
    call execute_command_line(trim(cmd),exitstat=ios)
    if(ios/=0) error stop 'Cannot create output folder'
    cmd='cmd /c cd > "'//trim(folder)//'\working_directory.txt"'
    call execute_command_line(trim(cmd),exitstat=ios)
    if(ios/=0) error stop 'Cannot query working directory'
    open(newunit=uw,file=trim(folder)//'\working_directory.txt',status='old',action='read')
    read(uw,'(a)',iostat=ios) cwd
    close(uw)
    if(ios/=0) error stop 'Cannot read working directory'
    ! Use the ASCII relative name for file I/O even under a Unicode parent directory.
    ! The cmd-generated current-directory text is for human-readable display only.
    display_folder=folder
    if(index(folder,':')==0.and.folder(1:2)/='\\') display_folder=trim(cwd)//'\'//trim(folder)
    print *, '============================================================'
    write(*,'(a)') 'OUTPUT FOLDER: '//trim(display_folder)
    print *, 'Trials per case = ',ntrials,' Tmax = ',tmax
    print *, 'Level 1=1e-4; level 2=1e-5; level 3=1e-6.'
    print *, 'Default: shared Brownian paths, endpoint-only capture detection.'
    print *, '============================================================'

    open(newunit=ui,file=trim(folder)//'\run_info.txt',status='new',action='write')
    write(ui,'(a)') 'R2C2 step-size check. This is not a new pursuit model.'
    write(ui,'(a)') 'Output folder: '//trim(display_folder)
    write(ui,'(a)') 'Compiler: '//compiler_version()
    write(ui,'(a)') 'Compiler options: '//compiler_options()
    write(ui,'(a)') 'master_seed='//trim(istr(master))//' trials='//trim(istr(ntrials))
    write(ui,'(a)') 'Tmax='//trim(rstr(tmax))//' bootstrap_resamples='//trim(istr(nboot))
    write(ui,'(a)') 'case_selection='//trim(istr(selected_case))//' level_selection='//trim(istr(selected_level))
    write(ui,'(a)') 'N=1 R=.1 S=1 ve=1; evader=(0,0), chaser=(1,0), internal state=(0,0).'
    write(ui,'(a)') 'Euler-Maruyama uses old states for ALL drift components.'
    write(ui,'(a)') 'Capture checked only at each level endpoint. No bridge/interpolation correction.'
    write(ui,'(a)') 'Fine increments sum to coarse increments while levels are active.'
    write(ui,'(a)') 'After fine capture, future Brownian increments can be sampled on coarser active grids.'
    write(ui,'(a)') 'RNG intrinsic to this compiler; exact replay requires same compiler/runtime and seed mapping.'
    write(ui,'(a)') 'Intervals: percentile bootstrap over independent trial IDs; paired resampling for differences.'
    write(ui,'(a)') 'When censored, compare min(T,Tmax); do not call its mean the unconditional MCT.'
    write(ui,'(a)') 'Shared-run CPU/wall time is joint, not a separate runtime for each level.'
    flush(ui)
    open(newunit=ut,file=trim(folder)//'\trajectories.csv',status='new',action='write')
    write(ut,'(a)') 'case_id,D,mu,a,trial_id,master_seed,h,observed_time,captured,censored,em_updates'
    open(newunit=us,file=trim(folder)//'\summary.csv',status='new',action='write')
    write(us,'(a)') 'case_id,D,mu,a,h,trials,Tmax,captured,censored,capture_rate,'// &
        'complete_mean,complete_mean_ci_low,complete_mean_ci_high,captured_only_mean,'// &
        'restricted_mean,restricted_mean_ci_low,restricted_mean_ci_high,observed_sd,em_updates'
    open(newunit=up,file=trim(folder)//'\paired_differences.csv',status='new',action='write')
    write(up,'(a)') 'case_id,D,mu,a,h_test,h_reference,trials,quantity,mean_difference,'// &
        'difference_ci_low,difference_ci_high,relative_percent,relative_ci_low,relative_ci_high'
    open(newunit=uc,file=trim(folder)//'\timing.csv',status='new',action='write')
    write(uc,'(a)') 'case_id,trials,selected_level,joint_wall_seconds,joint_cpu_seconds,'// &
        'wall_seconds_per_trial,updates_h1e4,updates_h1e5,updates_h1e6,brownian_draw_pairs'
    allocate(all_obs(ntrials,nl),all_cap(ntrials,nl))
    pair_l=[1,2,1];pair_r=[3,3,2]
    log_every=max(1,min(10,ntrials/5))
    do case_id=1,nc
        if(selected_case/=0.and.case_id/=selected_case) cycle
        print *, 'CASE ',case_id,' D=',noise_cases(case_id),' mu=',mu_cases(case_id),' a=',a_cases(case_id)
        case_updates=0;case_draws=0
        wall0=wall_now();call cpu_time(cpu0)
        do j=1,ntrials
            write(*,'(a,i0,a,i0)') '  Starting trial ',j,' / ',ntrials
            call seed_trial(master,case_id,j)
            call simulate_trial(noise_cases(case_id),mu_cases(case_id),a_cases(case_id), &
                tmax,selected_level,obs,cap,updates,draws,bad)
            if(bad) then
                write(ui,'(a)') 'INVALID numerical state: case='//trim(istr(case_id))//' trial='//trim(istr(j))
                flush(ui)
                error stop 'Non-finite numerical state; do not use this incomplete run'
            end if
            all_obs(j,:)=obs;all_cap(j,:)=cap
            case_updates=case_updates+updates;case_draws=case_draws+draws
            do l=1,nl
                if(selected_level/=0.and.l/=selected_level) cycle
                write(ut,'(a)') trim(istr(case_id))//','//trim(rstr(noise_cases(case_id)))//','// &
                    trim(rstr(mu_cases(case_id)))//','//trim(rstr(a_cases(case_id)))//','// &
                    trim(istr(j))//','//trim(istr(master))//','//trim(rstr(real(stride(l),dp)*fine_h))//','// &
                    trim(rstr(obs(l)))//','//trim(istr(merge(1,0,cap(l))))//','// &
                    trim(istr(merge(0,1,cap(l))))//','//trim(i64str(updates(l)))
            end do
            flush(ut)
            if(mod(j,log_every)==0.or.j==ntrials) then
                print *, '  Completed ',j,' / ',ntrials,' captures by level: ',count(all_cap(1:j,:),dim=1)
                print *, '  Simulation wall minutes: ',(wall_now()-wall0)/60.0_dp
            end if
        end do
        call cpu_time(cpu1);cpu_elapsed=cpu1-cpu0;elapsed=wall_now()-wall0
        write(uc,'(a)') trim(istr(case_id))//','//trim(istr(ntrials))//','//trim(istr(selected_level))//','// &
            trim(rstr(elapsed))//','//trim(rstr(cpu_elapsed))//','//trim(rstr(elapsed/real(ntrials,dp)))//','// &
            trim(i64str(case_updates(1)))//','//trim(i64str(case_updates(2)))//','// &
            trim(i64str(case_updates(3)))//','//trim(i64str(case_draws))
        flush(uc)
        call seed_trial(master,100+case_id,1)
        do l=1,nl
            if(selected_level/=0.and.l/=selected_level) cycle
            call bootstrap(all_obs(:,l),nboot,mean,lo,hi,sd)
            captured_count=count(all_cap(:,l))
            captext='NA';mct='NA';mctlo='NA';mcthi='NA'
            if(captured_count>0) then
                capmean=sum(all_obs(:,l),mask=all_cap(:,l))/real(captured_count,dp)
                captext=rstr(capmean)
            end if
            if(captured_count==ntrials) then
                mct=rstr(mean);mctlo=rstr(lo);mcthi=rstr(hi)
            end if
            write(us,'(a)') trim(istr(case_id))//','//trim(rstr(noise_cases(case_id)))//','// &
                trim(rstr(mu_cases(case_id)))//','//trim(rstr(a_cases(case_id)))//','// &
                trim(rstr(real(stride(l),dp)*fine_h))//','//trim(istr(ntrials))//','//trim(rstr(tmax))//','// &
                trim(istr(captured_count))//','//trim(istr(ntrials-captured_count))//','// &
                trim(rstr(real(captured_count,dp)/real(ntrials,dp)))//','// &
                trim(mct)//','//trim(mctlo)//','//trim(mcthi)//','//trim(captext)//','// &
                trim(rstr(mean))//','//trim(rstr(lo))//','//trim(rstr(hi))//','// &
                trim(rstr(sd))//','//trim(i64str(case_updates(l)))
        end do
        flush(us)
        if(selected_level==0) then
            do k=1,3
                l=pair_l(k);comparator=pair_r(k)
                quantity='restricted_mean'
                if(all(all_cap(:,l)).and.all(all_cap(:,comparator))) quantity='complete_sample_mean'
                call paired_bootstrap(all_obs(:,l),all_obs(:,comparator),nboot,delta,dlo,dhi,pct,plo,phi)
                write(up,'(a)') trim(istr(case_id))//','//trim(rstr(noise_cases(case_id)))//','// &
                    trim(rstr(mu_cases(case_id)))//','//trim(rstr(a_cases(case_id)))//','// &
                    trim(rstr(real(stride(l),dp)*fine_h))//','// &
                    trim(rstr(real(stride(comparator),dp)*fine_h))//','//trim(istr(ntrials))//','// &
                    trim(quantity)//','//trim(rstr(delta))//','//trim(rstr(dlo))//','//trim(rstr(dhi))//','// &
                    trim(rstr(pct))//','//trim(rstr(plo))//','//trim(rstr(phi))
            end do
            flush(up)
        end if
        write(ui,'(a)') 'COMPLETED case '//trim(istr(case_id))
        flush(ui)
    end do
    write(ui,'(a)') 'RUN COMPLETED SUCCESSFULLY'
    close(ui);close(ut);close(us);close(up);close(uc)
    print *, 'ALL REQUESTED CASES COMPLETED.'
    write(*,'(a)') 'OUTPUT FOLDER: '//trim(display_folder)
end program
