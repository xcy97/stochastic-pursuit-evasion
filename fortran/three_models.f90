! R2C5: full model A, aligned transient-speed model B, aligned steady-speed model C.
! Standalone Windows / Intel Fortran source; no other source files are required.
! Defaults: SIX parameter sets, 1000 paired independent trials PER set, h=1e-6.
! Copy this WHOLE file into a NEW console project. Select Release + x64.
! Production data are supplied separately in inputs/models/.
module r2c5_support
    use, intrinsic :: iso_fortran_env, only: real64, int64, compiler_version, compiler_options
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    implicit none
    integer, parameter :: dp=real64, nm=3, nc=6
    real(dp), parameter :: h=1.0e-6_dp, radius=0.1_dp, perception=1.0_dp, ve=1.0_dp, r_initial=1.0_dp
    real(dp), parameter :: pi=3.1415926535897932384626433832795_dp
    real(dp), parameter :: noise_cases(nc)=[.021544_dp,.215443_dp,31.6228_dp,.021544_dp,.215443_dp,31.6228_dp]
    real(dp), parameter :: mu_cases(nc)=[3._dp,3._dp,3._dp,30._dp,30._dp,30._dp]
    real(dp), parameter :: a_cases(nc)=[2.4_dp,2.4_dp,2.4_dp,29.97_dp,29.97_dp,29.97_dp]
    ! Retain the R2C2 seed domains for overlapping parameter sets.
    integer, parameter :: seed_cases(nc)=[5,3,2,6,7,4]
    character(1), parameter :: model_names(nm)=['A','B','C']
    ! Curves: first TWO trials only, sampled every .01 through time 20.
    integer, parameter :: example_trials=2
    real(dp), parameter :: curve_interval=.01_dp, curve_horizon=20._dp
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

    real(dp) function transient_speed(t,mu,a) result(v)
        real(dp),intent(in) :: t,mu,a
        if(mu*t>=40._dp) then
            ! exp(-40) is smaller than the rounding unit in 1-exp(-40).
            v=a/mu
        else
            v=(a/mu)*(1._dp-exp(-mu*t))
        end if
    end function

    real(dp) function analytic_reference(d,speed) result(value)
        real(dp),intent(in) :: d,speed
        real(dp),parameter :: expected_d(nc)=[.021544_dp,.215443_dp,31.6228_dp, &
                                             .021544_dp,.215443_dp,31.6228_dp]
        real(dp),parameter :: expected_v(nc)=[.8_dp,.8_dp,.8_dp,.999_dp,.999_dp,.999_dp]
        ! Independent evaluation of the manuscript MCT integral: quadrature orders
        ! 128 and 160 agree to relative tolerance 1e-7 for these six settings.
        real(dp),parameter :: tab(nc)=[ &
            1.5006037732858015e+01_dp,6.8876169520166224e+00_dp , &
            1.1772335081707598e+02_dp,3.8282469270811306e+00_dp , &
            3.9002321070993919e+00_dp,7.5676294412823751e+01_dp ]
        integer :: k
        value=-1._dp
        ! Do not silently reuse a fixed reference after changing model parameters.
        if(abs(radius-.1_dp)>1e-14_dp.or.abs(perception-1._dp)>1e-14_dp) return
        if(abs(ve-1._dp)>1e-14_dp.or.abs(r_initial-1._dp)>1e-14_dp) return
        do k=1,nc
            if(abs(d-expected_d(k))<1e-12_dp.and.abs(speed-expected_v(k))<1e-12_dp) then
                value=tab(k)
                return
            end if
        end do
    end function

    subroutine update_model(state,model,dw,d,mu,a,vb,speed_old,cos_old,cos_valid)
        real(dp),intent(inout) :: state(6)
        integer,intent(in) :: model
        real(dp),intent(in) :: dw(2),d,mu,a,vb
        real(dp),intent(out) :: speed_old,cos_old
        logical,intent(out) :: cos_valid
        real(dp) :: old(6),dx,dy,r,g
        old=state
        dx=old(1)-old(3);dy=old(2)-old(4)
        r=sqrt(dx*dx+dy*dy)
        if(r>1e-12_dp) then
            dx=dx/r;dy=dy/r
        else
            dx=0._dp;dy=0._dp
        end if
        g=exp(-(r-radius)/perception)
        cos_old=0._dp;cos_valid=.false.
        select case(model)
        case(1)
            speed_old=sqrt(old(5)*old(5)+old(6)*old(6))
            if(speed_old>1e-12_dp) then
                cos_old=max(-1._dp,min(1._dp,(old(5)*dx+old(6)*dy)/speed_old))
                cos_valid=.true.
            end if
        case(2)
            speed_old=vb
        case(3)
            speed_old=a/mu
        case default
            error stop 'Invalid model'
        end select
        ! Same old-state Euler-Maruyama position update for ALL three models.
        ! There is NO D/r term in these Cartesian equations.
        state(1)=old(1)+ve*g*dx*h+sqrt(2._dp*d)*dw(1)
        state(2)=old(2)+ve*g*dy*h+sqrt(2._dp*d)*dw(2)
        state(3)=old(3)+speed_old*dx*h
        state(4)=old(4)+speed_old*dy*h
        if(model==1) then
            state(5)=old(5)+(-mu*old(5)+a*dx)*h
            state(6)=old(6)+(-mu*old(6)+a*dy)*h
        end if
    end subroutine

    subroutine write_curve(unit_id,case_id,trial_id,model,t,state,mu,a,kind)
        integer,intent(in) :: unit_id,case_id,trial_id,model
        real(dp),intent(in) :: t,state(6),mu,a
        character(*),intent(in) :: kind
        real(dp) :: dx,dy,r,speed
        dx=state(1)-state(3);dy=state(2)-state(4);r=sqrt(dx*dx+dy*dy)
        select case(model)
        case(1)
            speed=sqrt(state(5)*state(5)+state(6)*state(6))
        case(2)
            speed=transient_speed(t,mu,a)
        case(3)
            speed=a/mu
        end select
        write(unit_id,'(a)') trim(istr(case_id))//','//trim(istr(trial_id))//','//model_names(model)//','// &
            trim(rstr(t))//','//trim(rstr(r))//','//trim(rstr(speed))//','//kind
    end subroutine

    subroutine simulate_models(d,mu,a,tmax,observed,captured,updates,diag,valid_cos,invalid, &
                               curve_unit,case_id,trial_id,terminal_states)
        real(dp),intent(in) :: d,mu,a,tmax
        real(dp),intent(out) :: observed(nm),diag(4)
        logical,intent(out) :: captured(nm),invalid
        integer(int64),intent(out) :: updates(nm),valid_cos
        integer,intent(in),optional :: curve_unit,case_id,trial_id
        real(dp),intent(out),optional :: terminal_states(6,nm)
        real(dp) :: states(6,nm),z(2),dw(2),t,told,vb,speed_old,cos_old
        real(dp) :: r2,sum_cos,sum_speed,sum_vb
        integer(int64) :: step,max_steps,next_report,next_curve,curve_stride,curve_end
        integer :: m
        logical :: active(nm),cos_valid,record_curves
        states=0._dp;states(3,:)=r_initial
        observed=tmax;captured=.false.;updates=0;invalid=.false.;active=.true.
        sum_cos=0._dp;sum_speed=0._dp;sum_vb=0._dp;valid_cos=0;diag=0._dp
        max_steps=nint(tmax/h,kind=int64)
        next_report=10000000_int64
        curve_stride=max(1_int64,nint(curve_interval/h,kind=int64))
        curve_end=nint(curve_horizon/h,kind=int64);next_curve=curve_stride
        record_curves=present(curve_unit).and.present(case_id).and.present(trial_id)
        if(record_curves) then
            do m=1,nm
                call write_curve(curve_unit,case_id,trial_id,m,0._dp,states(:,m),mu,a,'initial')
            end do
        end if
        do step=1,max_steps
            told=real(step-1_int64,dp)*h;t=real(step,dp)*h
            call gaussian_pair(z);dw=sqrt(h)*z
            vb=transient_speed(told,mu,a)
            do m=1,nm
                if(.not.active(m)) cycle
                call update_model(states(:,m),m,dw,d,mu,a,vb,speed_old,cos_old,cos_valid)
                updates(m)=updates(m)+1
                if(m==1) then
                    sum_speed=sum_speed+speed_old;sum_vb=sum_vb+vb
                    if(cos_valid) then
                        sum_cos=sum_cos+cos_old;valid_cos=valid_cos+1
                    end if
                end if
                if(.not.all(ieee_is_finite(states(:,m)))) then
                    invalid=.true.
                    return
                end if
                r2=(states(1,m)-states(3,m))**2+(states(2,m)-states(4,m))**2
                if(r2<=radius*radius) then
                    captured(m)=.true.;observed(m)=t;active(m)=.false.
                    if(record_curves.and.step<=curve_end) then
                        call write_curve(curve_unit,case_id,trial_id,m,t,states(:,m),mu,a,'capture')
                    end if
                end if
            end do
            if(record_curves.and.step==next_curve.and.step<=curve_end) then
                do m=1,nm
                    if(active(m)) call write_curve(curve_unit,case_id,trial_id,m,t,states(:,m),mu,a,'grid')
                end do
                next_curve=next_curve+curve_stride
                flush(curve_unit)
            end if
            if(step==next_report) then
                write(*,'(a,f14.6,a,3l2)') '    Within-trial time=',t,' active A/B/C:',active
                next_report=next_report+10000000_int64
            end if
            if(.not.any(active)) exit
        end do
        if(valid_cos>0) diag(1)=sum_cos/real(valid_cos,dp)
        if(updates(1)>0) then
            diag(2)=sum_speed/real(updates(1),dp)
            diag(3)=sum_vb/real(updates(1),dp)
        end if
        if(sum_vb>0._dp) diag(4)=(sum_vb-sum_speed)/sum_vb
        if(present(terminal_states)) terminal_states=states
    end subroutine

    subroutine pair_stats(x,y,baseline,b,delta,lo,hi,pct,plo,phi)
        real(dp),intent(in) :: x(:),y(:),baseline(:)
        integer,intent(in) :: b
        real(dp),intent(out) :: delta,lo,hi,pct,plo,phi
        real(dp),allocatable :: differences(:),percentages(:)
        real(dp) :: sx,sy,sa,u
        integer :: n,k,j,index
        n=size(x);delta=sum(x-y)/real(n,dp);pct=100._dp*sum(x-y)/sum(baseline)
        allocate(differences(b),percentages(b))
        do k=1,b
            sx=0._dp;sy=0._dp;sa=0._dp
            do j=1,n
                call random_number(u);index=1+int(u*n)
                sx=sx+x(index);sy=sy+y(index);sa=sa+baseline(index)
            end do
            differences(k)=(sx-sy)/real(n,dp);percentages(k)=100._dp*(sx-sy)/sa
        end do
        call quicksort(differences,1,b);call quicksort(percentages,1,b)
        lo=percentile(differences,.025_dp);hi=percentile(differences,.975_dp)
        plo=percentile(percentages,.025_dp);phi=percentile(percentages,.975_dp)
    end subroutine
end module

program r2c5_three_models
    use r2c5_support
    implicit none
    ! USER SETTINGS: defaults run the full experiment, not a 20-path pilot.
    integer :: ntrials=1000,master=20261023,nboot=2000,selected_case=0,first_trial=1,curves=1
    real(dp) :: tmax=100000._dp
    character(2048) :: output_root='results',folder,display_folder,arg,cwd,cmd
    character(32) :: stamp
    integer :: values(8),i,j,m,k,c,trial,ios,ui,ut,us,up,uc,ur,uw,ct,early_count,diag_count
    integer :: lhs(3),rhs(3)
    real(dp) :: obs(nm),diag(4),cpu0,cpu1,wall0,elapsed,cpu_elapsed,mean,lo,hi,sd
    real(dp) :: capmean,delta,dlo,dhi,pct,plo,phi,reference
    real(dp),allocatable :: all_obs(:,:),all_diag(:,:)
    logical :: cap(nm),invalid
    logical,allocatable :: all_cap(:,:)
    integer(int64) :: updates(nm),valid_cos,total_updates(nm),case_draws,end_tick
    integer(int64),allocatable :: alignment_counts(:)
    character(64) :: complete,complete_lo,complete_hi,captext,reftext,quantity
    character(64) :: cos_text,speed_text,aligned_text,deficit_text,mean_cos_text,mean_deficit_text
    character(64) :: c_diff,c_percent,c_lo,c_hi
    character(9),parameter :: pair_names(3)=['A_minus_B','B_minus_C','A_minus_C']

    do i=1,command_argument_count()
        call get_command_argument(i,arg)
        if(index(arg,'--trials=')==1) then
            read(arg(10:),*,iostat=ios) ntrials
        else if(index(arg,'--tmax=')==1) then
            read(arg(8:),*,iostat=ios) tmax
        else if(index(arg,'--seed=')==1) then
            read(arg(8:),*,iostat=ios) master
        else if(index(arg,'--case=')==1) then
            read(arg(8:),*,iostat=ios) selected_case
        else if(index(arg,'--first-trial=')==1) then
            read(arg(15:),*,iostat=ios) first_trial
        else if(index(arg,'--bootstrap=')==1) then
            read(arg(13:),*,iostat=ios) nboot
        else if(index(arg,'--curves=')==1) then
            read(arg(10:),*,iostat=ios) curves
        else if(index(arg,'--output=')==1) then
            output_root=arg(10:);ios=0
        else
            print *, 'Unknown argument: ',trim(arg)
            error stop 'Invalid command-line option'
        end if
        if(ios/=0) error stop 'Invalid argument value'
    end do
    if(ntrials<2.or.ntrials>1000000) error stop 'Invalid trial count'
    if(first_trial<1.or.first_trial>huge(first_trial)-ntrials) error stop 'Invalid first trial ID'
    if(nboot<100.or.nboot>100000) error stop 'Invalid bootstrap count'
    if(selected_case<0.or.selected_case>nc) error stop 'Invalid case selection'
    if(curves/=0.and.curves/=1) error stop 'Curves option must be 0 or 1'
    if(.not.ieee_is_finite(tmax)) error stop 'Nonfinite Tmax'
    if(tmax<h.or.tmax>1e9_dp) error stop 'Invalid Tmax'
    if(h<=0._dp.or.radius<=0._dp.or.perception<=0._dp.or.r_initial<=radius) error stop 'Invalid scales'
    if(any(mu_cases<=0._dp).or.any(a_cases<0._dp).or.any(noise_cases<0._dp)) error stop 'Invalid parameters'
    if(ve<0._dp) error stop 'Invalid escape scale'
    if(any(mu_cases*h>=1._dp)) error stop 'Time step too large for internal-state update'
    end_tick=nint(tmax/h,kind=int64)
    if(abs(real(end_tick,dp)*h-tmax)>max(10._dp*spacing(tmax),1e-6_dp*h)) error stop 'Tmax is not on grid'
    do i=1,len_trim(output_root)
        if(iachar(output_root(i:i))>127) error stop 'Use an ASCII relative output name, e.g. results'
        if(output_root(i:i)=='"'.or.output_root(i:i)=='%') error stop 'Invalid output directory'
    end do
    call date_and_time(values=values)
    write(stamp,'(i4.4,2i2.2,a,3i2.2,a,i3.3)') values(1:3),'_',values(5:7),'_',values(8)
    folder=trim(output_root)//'\R2C5_run_'//trim(stamp)
    cmd='cmd /c mkdir "'//trim(folder)//'"'
    call execute_command_line(trim(cmd),exitstat=ios)
    if(ios/=0) error stop 'Cannot create output directory'
    cmd='cmd /c cd > "'//trim(folder)//'\working_directory.txt"'
    call execute_command_line(trim(cmd),exitstat=ios)
    if(ios/=0) error stop 'Cannot get working directory'
    open(newunit=uw,file=trim(folder)//'\working_directory.txt',status='old',action='read')
    read(uw,'(a)',iostat=ios) cwd
    close(uw)
    if(ios/=0) error stop 'Cannot read working directory'
    ! Keep relative ASCII names for Intel file I/O under a Chinese parent directory.
    display_folder=folder
    if(index(folder,':')==0.and.folder(1:2)/='\\') display_folder=trim(cwd)//'\'//trim(folder)
    write(*,'(a)') 'OUTPUT FOLDER: '//trim(display_folder)
    print *, 'Trials per case=',ntrials,' h=',h,' Tmax=',tmax
    print *, 'A=full; B=aligned transient; C=aligned constant terminal speed.'
    print *, 'Six parameter cases; a new output folder is created on each run.'
    open(newunit=ui,file=trim(folder)//'\run_info.txt',status='new',action='write')
    write(ui,'(a)') 'R2C5 three-model experiment, source version 2026-10-23.'
    write(ui,'(a)') 'Output folder: '//trim(display_folder)
    write(ui,'(a)') 'Compiler: '//compiler_version()
    write(ui,'(a)') 'Compiler options: '//compiler_options()
    write(ui,'(a)') 'trials='//trim(istr(ntrials))//' first_trial='//trim(istr(first_trial))
    write(ui,'(a)') 'master_seed='//trim(istr(master))//' bootstrap_resamples='//trim(istr(nboot))
    write(ui,'(a)') 'h='//trim(rstr(h))//' Tmax='//trim(rstr(tmax))
    write(ui,'(a)') 'N=1; R='//trim(rstr(radius))//' S='//trim(rstr(perception))//' ve='//trim(rstr(ve))
    write(ui,'(a)') 'r_initial='//trim(rstr(r_initial))//' case_selection='//trim(istr(selected_case))
    write(ui,'(a)') 'Evader=(0,0); chaser=(r_initial,0); internal state A=(0,0).'
    write(ui,'(a)') 'A: full original Cartesian position/internal-state equations.'
    write(ui,'(a)') 'B: aligned speed (a/mu)*(1-exp(-mu*t)); from rest, evaluated at OLD step time.'
    write(ui,'(a)') 'C: speed a/mu from t=0; NOT initialized with zero speed.'
    write(ui,'(a)') 'All models share each Cartesian Brownian increment, not positions/directions.'
    write(ui,'(a)') 'Each model uses its own line of sight and endpoint-only capture detection.'
    write(ui,'(a)') 'No radial D/r drift is added to Cartesian equations. No bridge correction.'
    write(ui,'(a)') 'Sequential differences are A-B, B-C and A-C. These are not order-independent causes.'
    write(ui,'(a)') 'Percentages ALL divide by the corresponding mean of A, so point estimates add.'
    write(ui,'(a)') 'CI: percentile bootstrap over independent trial IDs; pairs resampled together.'
    write(ui,'(a)') 'When censored, paired comparisons ALL use observed min(T,Tmax), not full MCT.'
    write(ui,'(a)') 'Alignment diagnostics: per-trial time averages, then unweighted across trials.'
    write(ui,'(a)') 'mean_cos_A excludes zero-speed points; speed deficit compares A with B over A window.'
    write(ui,'(a)') 'h=1e-6 is a numerical choice, NOT an exact continuous-time reference.'
    write(ui,'(a)') 'Analytic_C_reference is the existing MCT integral, checked at orders 128/160.'
    write(ui,'(a)') 'Fixed analytic lookup returns NA if D,speed,R,S,ve or r_initial are changed.'
    write(ui,'(a)') 'Curve output uses first two local trial IDs, dt=.01 and t<=20; not the whole long tail.'
    write(ui,'(a)') 'Random replay requires same compiler/runtime/architecture and seed mapping.'
    write(ui,'(a)') 'Only completed trial groups are flushed; no automatic restart from partial trials.'
    do c=1,nc
        write(ui,'(a)') 'CASE '//trim(istr(c))//' seed_case='//trim(istr(seed_cases(c)))// &
            ' D='//trim(rstr(noise_cases(c)))//' mu='//trim(rstr(mu_cases(c)))//' a='//trim(rstr(a_cases(c)))
    end do
    flush(ui)
    open(newunit=ut,file=trim(folder)//'\trajectories.csv',status='new',action='write')
    write(ut,'(a)') 'case_id,D,mu,a,trial_id,seed_case,master_seed,model,h,Tmax,observed_time,'// &
        'captured,censored,em_updates,alignment_samples_A,mean_cos_A,mean_speed_A,'// &
        'mean_aligned_speed_on_A_window,speed_deficit_ratio_A'
    open(newunit=us,file=trim(folder)//'\summary.csv',status='new',action='write')
    write(us,'(a)') 'case_id,D,mu,a,model,h,trials,Tmax,captured,censored,capture_rate,'// &
        'complete_mean,complete_mean_ci_low,complete_mean_ci_high,captured_only_mean,'// &
        'restricted_mean,restricted_mean_ci_low,restricted_mean_ci_high,observed_sd,em_updates,'// &
        'observed_early_capture_fraction,mean_cos_A,speed_deficit_ratio_A,analytic_C_reference,'// &
        'C_mean_minus_analytic,C_percent_minus_analytic,C_percent_ci_low,C_percent_ci_high'
    open(newunit=up,file=trim(folder)//'\paired_differences.csv',status='new',action='write')
    write(up,'(a)') 'case_id,D,mu,a,h,trials,comparison,quantity,mean_difference,difference_ci_low,'// &
        'difference_ci_high,percent_of_A_mean,percent_ci_low,percent_ci_high'
    open(newunit=uc,file=trim(folder)//'\timing.csv',status='new',action='write')
    write(uc,'(a)') 'case_id,trials,joint_wall_seconds,joint_cpu_seconds,wall_seconds_per_trial,'// &
        'updates_A,updates_B,updates_C,brownian_draw_pairs'
    open(newunit=ur,file=trim(folder)//'\r_curves.csv',status='new',action='write')
    write(ur,'(a)') 'case_id,trial_id,model,time,r,speed,sample_kind'
    allocate(all_obs(ntrials,nm),all_cap(ntrials,nm),all_diag(ntrials,4),alignment_counts(ntrials))
    lhs=[1,2,1];rhs=[2,3,3]
    do c=1,nc
        if(selected_case/=0.and.c/=selected_case) cycle
        print *, 'CASE ',c,' D=',noise_cases(c),' mu=',mu_cases(c),' a=',a_cases(c)
        total_updates=0;case_draws=0;wall0=wall_now();call cpu_time(cpu0)
        do j=1,ntrials
            trial=first_trial+j-1
            write(*,'(a,i0,a,i0,a,i0)') '  Starting ',j,' / ',ntrials,' trial_id=',trial
            call seed_trial(master,seed_cases(c),trial)
            if(curves==1.and.j<=example_trials) then
                call simulate_models(noise_cases(c),mu_cases(c),a_cases(c),tmax,obs,cap,updates,diag, &
                    valid_cos,invalid,ur,c,trial)
            else
                call simulate_models(noise_cases(c),mu_cases(c),a_cases(c),tmax,obs,cap,updates,diag, &
                    valid_cos,invalid)
            end if
            if(invalid) then
                write(ui,'(a)') 'INVALID STATE case='//trim(istr(c))//' trial='//trim(istr(trial))
                flush(ui)
                error stop 'Nonfinite state; do not use this incomplete run as a completed experiment'
            end if
            all_obs(j,:)=obs;all_cap(j,:)=cap;all_diag(j,:)=diag;alignment_counts(j)=valid_cos
            total_updates=total_updates+updates;case_draws=case_draws+maxval(updates)
            do m=1,nm
                cos_text='NA';speed_text='NA';aligned_text='NA';deficit_text='NA'
                if(m==1) then
                    if(valid_cos>0) cos_text=rstr(diag(1))
                    speed_text=rstr(diag(2));aligned_text=rstr(diag(3))
                    if(diag(3)>0._dp) deficit_text=rstr(diag(4))
                end if
                write(ut,'(a)') trim(istr(c))//','//trim(rstr(noise_cases(c)))//','// &
                    trim(rstr(mu_cases(c)))//','//trim(rstr(a_cases(c)))//','//trim(istr(trial))//','// &
                    trim(istr(seed_cases(c)))//','//trim(istr(master))//','//model_names(m)//','// &
                    trim(rstr(h))//','//trim(rstr(tmax))//','//trim(rstr(obs(m)))//','// &
                    trim(istr(merge(1,0,cap(m))))//','//trim(istr(merge(0,1,cap(m))))//','// &
                    trim(i64str(updates(m)))//','//trim(i64str(merge(valid_cos,0_int64,m==1)))//','// &
                    trim(cos_text)//','//trim(speed_text)//','//trim(aligned_text)//','//trim(deficit_text)
            end do
            flush(ut);flush(ur)
            if(mod(j,10)==0.or.j==ntrials) then
                print *, '  Completed ',j,' / ',ntrials,' captured A/B/C:',count(all_cap(1:j,:),dim=1)
                print *, '  Simulation wall minutes: ',(wall_now()-wall0)/60._dp
            end if
        end do
        call cpu_time(cpu1);cpu_elapsed=cpu1-cpu0;elapsed=wall_now()-wall0
        write(uc,'(a)') trim(istr(c))//','//trim(istr(ntrials))//','//trim(rstr(elapsed))//','// &
            trim(rstr(cpu_elapsed))//','//trim(rstr(elapsed/real(ntrials,dp)))//','// &
            trim(i64str(total_updates(1)))//','//trim(i64str(total_updates(2)))//','// &
            trim(i64str(total_updates(3)))//','//trim(i64str(case_draws))
        flush(uc)
        call seed_trial(master,200+seed_cases(c),1)
        reference=analytic_reference(noise_cases(c),a_cases(c)/mu_cases(c));reftext='NA'
        if(reference>0._dp) reftext=rstr(reference)
        do m=1,nm
            call bootstrap(all_obs(:,m),nboot,mean,lo,hi,sd)
            ct=count(all_cap(:,m));complete='NA';complete_lo='NA';complete_hi='NA';captext='NA'
            if(ct>0) then
                capmean=sum(all_obs(:,m),mask=all_cap(:,m))/real(ct,dp);captext=rstr(capmean)
            end if
            if(ct==ntrials) then
                complete=rstr(mean);complete_lo=rstr(lo);complete_hi=rstr(hi)
            end if
            early_count=count(all_cap(:,m).and.all_obs(:,m)<=3._dp/mu_cases(c))
            mean_cos_text='NA';mean_deficit_text='NA'
            if(m==1) then
                diag_count=count(alignment_counts>0)
                if(diag_count>0) mean_cos_text=rstr( &
                    sum(all_diag(:,1),mask=alignment_counts>0)/real(diag_count,dp))
                diag_count=count(all_diag(:,3)>0._dp)
                if(diag_count>0) mean_deficit_text=rstr( &
                    sum(all_diag(:,4),mask=all_diag(:,3)>0._dp)/real(diag_count,dp))
            end if
            c_diff='NA';c_percent='NA';c_lo='NA';c_hi='NA'
            if(m==3.and.ct==ntrials.and.reference>0._dp) then
                c_diff=rstr(mean-reference);c_percent=rstr(100._dp*(mean-reference)/reference)
                c_lo=rstr(100._dp*(lo-reference)/reference);c_hi=rstr(100._dp*(hi-reference)/reference)
            end if
            write(us,'(a)') trim(istr(c))//','//trim(rstr(noise_cases(c)))//','//trim(rstr(mu_cases(c)))//','// &
                trim(rstr(a_cases(c)))//','//model_names(m)//','//trim(rstr(h))//','// &
                trim(istr(ntrials))//','//trim(rstr(tmax))//','//trim(istr(ct))//','// &
                trim(istr(ntrials-ct))//','//trim(rstr(real(ct,dp)/real(ntrials,dp)))//','// &
                trim(complete)//','//trim(complete_lo)//','//trim(complete_hi)//','//trim(captext)//','// &
                trim(rstr(mean))//','//trim(rstr(lo))//','//trim(rstr(hi))//','//trim(rstr(sd))//','// &
                trim(i64str(total_updates(m)))//','//trim(rstr(real(early_count,dp)/real(ntrials,dp)))//','// &
                trim(mean_cos_text)//','//trim(mean_deficit_text)//','//trim(reftext)//','// &
                trim(c_diff)//','//trim(c_percent)//','//trim(c_lo)//','//trim(c_hi)
        end do
        flush(us)
        quantity='restricted_mean'
        if(all(all_cap)) quantity='complete_sample_mean'
        do k=1,3
            call pair_stats(all_obs(:,lhs(k)),all_obs(:,rhs(k)),all_obs(:,1),nboot, &
                            delta,dlo,dhi,pct,plo,phi)
            write(up,'(a)') trim(istr(c))//','//trim(rstr(noise_cases(c)))//','//trim(rstr(mu_cases(c)))//','// &
                trim(rstr(a_cases(c)))//','//trim(rstr(h))//','//trim(istr(ntrials))//','// &
                pair_names(k)//','//trim(quantity)//','//trim(rstr(delta))//','//trim(rstr(dlo))//','// &
                trim(rstr(dhi))//','//trim(rstr(pct))//','//trim(rstr(plo))//','//trim(rstr(phi))
        end do
        flush(up)
        write(ui,'(a)') 'COMPLETED case '//trim(istr(c));flush(ui)
    end do
    write(ui,'(a)') 'RUN COMPLETED SUCCESSFULLY'
    close(ui);close(ut);close(us);close(up);close(uc);close(ur)
    print *, 'ALL REQUESTED CASES COMPLETED.'
    write(*,'(a)') 'OUTPUT FOLDER: '//trim(display_folder)
end program
