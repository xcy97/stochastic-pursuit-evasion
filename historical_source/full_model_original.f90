! Historical unseeded scan; see documentation/PROVENANCE.md.
program phase_newmodel
    implicit none
    integer, parameter :: MaxHoundNum = 32
    integer, parameter :: Nmax = 4*MaxHoundNum + 2
    integer, parameter :: HoundCases(7) = [1,2,3,5,11,17,32]
    integer, parameter :: NumCases = 7
    integer, parameter :: M = 15
    integer, parameter :: NN = 100000
    real*8, parameter :: PI = 3.141592653589793238d0
    real*8, parameter :: hh = 1d-4
    real*8, parameter :: TTT = 1000d0
    real*8, parameter :: R = 0.1d0
    real*8, parameter :: sigma = 0.0d0
    real*8, parameter :: SS = 1.0d0
    real*8, parameter :: ve = 1.0d0
    real*8, parameter :: mu = 0.2d0
    real*8, parameter :: a_default = 0.5d0
    integer :: i, j, k, j1, case_idx, step, max_steps
    real*8 :: t0, t, noise1, noise2, CT11, start_time, end_time, elapsed_time
    real*8, dimension(Nmax) :: Y0, Y, k1
    real*8, dimension(M) :: D
    real*8, dimension(NumCases) :: CT_all
    real*8, dimension(NumCases) :: success_rate_all
    real*8, dimension(MaxHoundNum) :: Y_check
    integer :: output_unit
    integer :: output_unit2
    integer :: num_timeouts
    integer :: successes
    real*8  :: success_rate
    real*8  :: Y_check1
    real*8, dimension(MaxHoundNum) :: a_vals
    real*8 :: U1, U2, U3, U4
    open(unit=200, file='D.txt', status='old', action='read')
    do j=1,M
        read(200,*) D(j)
    end do
    close(200)
    do j=1,MaxHoundNum
        a_vals(j) = a_default
    end do
    call random_seed()
    output_unit = 100
    open(unit=output_unit, file='CT_d2N2_Blind_newmodel_NoG 10的五次方 .txt', status='unknown')
    output_unit2 = 101
    open(unit=output_unit2, file='success_rate_results_NoG 10的五次方 .txt', status='unknown')
    call cpu_time(start_time)
    do k=1,M
        print *, "========== 开始第", k, "组 (噪声 D=", D(k), ") =========="
        do i = 1, NumCases
            success_rate_all(i) = 0.0d0
        end do
        do case_idx = 1, NumCases
            print *, ">>> 正在运行猎犬数量 N =", HoundCases(case_idx)
            CT11 = 0.0d0
            num_timeouts = 0
            do j = 1, NN
                t0 = 0.0d0
                Y0 = 0.0d0
                Y0(1) = 0.0d0
                Y0(2) = 0.0d0
                do j1 = 1, HoundCases(case_idx)
                    Y0(2 + 4*(j1-1) + 1) = cos(PI*2.0d0*(j1-1)/HoundCases(case_idx))
                    Y0(2 + 4*(j1-1) + 2) = sin(PI*2.0d0*(j1-1)/HoundCases(case_idx))
                    Y0(2 + 4*(j1-1) + 3) = 0.0d0
                    Y0(2 + 4*(j1-1) + 4) = 0.0d0
                end do
                t = t0
                Y = Y0
                Y_check1 = 1.0d0
                max_steps = int(TTT / hh) + 1
                do step = 1, max_steps
                    call random_number(U1)
                    call random_number(U2)
                    call random_number(U3)
                    call random_number(U4)
                    noise1 = sqrt(-2.0d0*log(U1)/hh) * cos(2.0d0*PI*U2)
                    noise2 = sqrt(-2.0d0*log(U3)/hh) * cos(2.0d0*PI*U4)
                    call FCN_Blind(k1, t, Y, D(k), noise1, noise2, HoundCases(case_idx), a_vals)
                    Y = Y + hh * k1
                    t = t + hh
                    do j1 = 1, HoundCases(case_idx)
                        Y_check(j1) = sqrt( (Y(1) - Y(2 + 4*(j1-1) + 1))**2 + (Y(2) - Y(2 + 4*(j1-1) + 2))**2 )
                    end do
                    Y_check1 = minval(Y_check(1:HoundCases(case_idx)))
                    if (Y_check1 <= R) then
                        CT11 = CT11 + t
                        exit
                    end if
                    if (step == max_steps) then
                        num_timeouts = num_timeouts + 1
                        exit
                    end if
                end do
            end do
            successes = NN - num_timeouts
            if (successes > 0) then
                CT_all(case_idx) = CT11 / dble(successes)
            else
                CT_all(case_idx) = -1.0d0
            end if
            success_rate = dble(successes) / dble(NN)
            success_rate_all(case_idx) = success_rate
            print *, ">>> noise D=", D(k), " N=", HoundCases(case_idx), &
                     " successes=", successes, " timeouts=", num_timeouts, &
                     " success_rate=", success_rate, " avgCT=", CT_all(case_idx)
        end do
        write(output_unit, "(8f12.6)") D(k), CT_all
        flush(output_unit)
        write(output_unit2, "(8f12.6)") D(k), success_rate_all
        flush(output_unit2)
        call cpu_time(end_time)
        elapsed_time = end_time - start_time
        print *, ">>> 完成第", k, "/", M, "组"
        print *, ">>> 当前用时 ", elapsed_time/60d0, "分钟"
        print *, ">>> 预计剩余 ", (elapsed_time/k)*(M-k)/60d0, "分钟"
    end do
    close(output_unit)
    close(output_unit2)
    print *, "========== 全部完成 =========="
contains
    subroutine FCN_Blind(YPRIME, tt, YY, DD, kesit1, kesit2, HoundNum, a_vals)
        implicit none
        integer :: j1, HoundNum
        real*8 :: tt, YY(Nmax), YPRIME(Nmax), DD, kesit1, kesit2
        real*8, intent(in) :: a_vals(:)
        real*8 :: dx, dy, dist_r, g_val, Ex, Ey
        real*8 :: vx, vy, Vmag
        integer :: posx, posy, vxidx, vyidx
        real*8, parameter :: eps = 1.0d-12
        real*8 :: a_n
        YPRIME = 0.0d0
        Ex = 0.0d0
        Ey = 0.0d0
        do j1 = 1, HoundNum
            posx = 2 + 4*(j1-1) + 1
            posy = posx + 1
            dx = YY(1) - YY(posx)
            dy = YY(2) - YY(posy)
            dist_r = sqrt(dx*dx + dy*dy)
            if (dist_r > eps) then
                g_val = exp( -(dist_r - R) / SS )
                Ex = Ex + g_val * (dx / dist_r)
                Ey = Ey + g_val * (dy / dist_r)
            end if
        end do
        Ex = ve * Ex / HoundNum
        Ey = ve * Ey / HoundNum
        YPRIME(1) = sqrt(2.0d0 * DD) * kesit1 + Ex
        YPRIME(2) = sqrt(2.0d0 * DD) * kesit2 + Ey
        do j1 = 1, HoundNum
            posx = 2 + 4*(j1-1) + 1
            posy = posx + 1
            vxidx = posx + 2
            vyidx = posx + 3
            dx = YY(1) - YY(posx)
            dy = YY(2) - YY(posy)
            dist_r = sqrt(dx*dx + dy*dy)
            if (dist_r > eps) then
                dx = dx / dist_r
                dy = dy / dist_r
            else
                dx = 0.0d0
                dy = 0.0d0
            end if
            vx = YY(vxidx)
            vy = YY(vyidx)
            Vmag = sqrt(vx*vx + vy*vy)
            a_n = a_vals(j1)
            YPRIME(posx)     = Vmag * dx
            YPRIME(posy)     = Vmag * dy
            YPRIME(vxidx) = -mu * vx + a_n * dx
            YPRIME(vyidx) = -mu * vy + a_n * dy
        end do
    end subroutine FCN_Blind
end program phase_newmodel
