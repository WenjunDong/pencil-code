! $Id: nohydro.f90,v 1.43 2005-10-06 08:04:37 ajohan Exp $

!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: lhydro = .false.
! MVAR CONTRIBUTION 0
! MAUX CONTRIBUTION 0
!
! PENCILS PROVIDED oo,uij,uu,u2,sij,divu
!
!***************************************************************

module Hydro

  use Cparam
  use Density
  use Messages

  implicit none

  include 'hydro.h'

  real :: othresh=0.,othresh_per_orms=0.,orms=0.,othresh_scl=1.
  real :: nu_turb=0.,nu_turb0=0.,tau_nuturb=0.,nu_turb1=0.
  logical :: lcalc_turbulence_pars=.false.
  real :: kep_cutoff_pos_ext= huge(1.0),kep_cutoff_width_ext=0.0
  real :: kep_cutoff_pos_int=-huge(1.0),kep_cutoff_width_int=0.0
  real :: u_out_kep=0.0

  real, allocatable, dimension (:,:) :: KS_k,KS_A,KS_B !or through whole field for each wavenumber? 
  real, allocatable, dimension (:) :: KS_omega !or through whole field for each wavenumber? 
  integer :: KS_modes = 32
  !namelist /hydro_init_pars/ dummyuu
  !namelist /hydro_run_pars/  dummyuu

  real :: theta=0.
  real :: Hp,cs_ave,alphaSS,ul0,tl0,eps_diss,teta,ueta,tl01,teta1

  ! other variables (needs to be consistent with reset list below)
  integer :: idiag_u2m=0,idiag_um2=0,idiag_oum=0,idiag_o2m=0
  integer :: idiag_uxpt=0,idiag_uypt=0,idiag_uzpt=0
  integer :: idiag_dtu=0,idiag_dtv=0,idiag_urms=0,idiag_umax=0,idiag_uzrms=0
  integer :: idiag_uzmax=0,idiag_orms=0,idiag_omax=0
  integer :: idiag_ux2m=0,idiag_uy2m=0,idiag_uz2m=0
  integer :: idiag_uxuym=0,idiag_uxuzm=0,idiag_uyuzm=0,idiag_oumphi=0
  integer :: idiag_ruxm=0,idiag_ruym=0,idiag_ruzm=0,idiag_rumax=0
  integer :: idiag_uxmz=0,idiag_uymz=0,idiag_uzmz=0,idiag_umx=0
  integer :: idiag_umy=0,idiag_umz=0,idiag_uxmxy=0,idiag_uymxy=0,idiag_uzmxy=0
  integer :: idiag_Marms=0,idiag_Mamax=0,idiag_divu2m=0,idiag_epsK=0
  integer :: idiag_urmphi=0,idiag_upmphi=0,idiag_uzmphi=0,idiag_u2mphi=0
  integer :: idiag_ekintot=0, idiag_ekin=0

  contains

!***********************************************************************
    subroutine register_hydro()
!
!  Initialise variables which should know that we solve the hydro
!  equations: iuu, etc; increase nvar accordingly.
!
!  6-nov-01/wolf: coded
!
      use Cdata
      use Mpicomm, only: lroot,stop_it
      use Sub
!
      logical, save :: first=.true.
!
      if (.not. first) call stop_it('register_hydro called twice')
      first = .false.
!
!ajwm      lhydro = .false.
!
!  identify version number (generated automatically by CVS)
!
      if (lroot) call cvs_id( &
           "$Id: nohydro.f90,v 1.43 2005-10-06 08:04:37 ajohan Exp $")
!
    endsubroutine register_hydro
!***********************************************************************
    subroutine initialize_hydro(f,lstarting)
!
!  Perform any post-parameter-read initialization i.e. calculate derived
!  parameters.
!
!  24-nov-02/tony: coded 
!
      use Cdata, only: kinflow
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      logical :: lstarting
!      
      if (kinflow=='KS') then
        call random_isotropic_KS_setup(-5./3.,1.,(nx-1.)/2)
      endif
! 
      if (ip == 0) print*,f,lstarting  !(keep compiler quiet)
!
    endsubroutine initialize_hydro
!***********************************************************************
    subroutine read_hydro_init_pars(unit,iostat)
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat
                                                                                                   
      if (present(iostat) .and. (NO_WARN)) print*,iostat
      if (NO_WARN) print*,unit
                                                                                                   
    endsubroutine read_hydro_init_pars
!***********************************************************************
    subroutine write_hydro_init_pars(unit)
      integer, intent(in) :: unit
                                                                                                   
      if (NO_WARN) print*,unit
                                                                                                   
    endsubroutine write_hydro_init_pars
!***********************************************************************
    subroutine read_hydro_run_pars(unit,iostat)
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat
                                                                                                   
      if (present(iostat) .and. (NO_WARN)) print*,iostat
      if (NO_WARN) print*,unit
                                                                                                   
    endsubroutine read_hydro_run_pars
!***********************************************************************
    subroutine write_hydro_run_pars(unit)
      integer, intent(in) :: unit
                                                                                                   
      if (NO_WARN) print*,unit
    endsubroutine write_hydro_run_pars
!***********************************************************************
    subroutine init_uu(f,xx,yy,zz)
!
!  initialise uu and lnrho; called from start.f90
!  Should be located in the Hydro module, if there was one.
!
!   7-jun-02/axel: adapted from hydro
!
      use Cdata
      use Sub
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz) :: xx,yy,zz
!
      if(NO_WARN) print*,f,xx,yy,zz  !(keep compiler quiet)
    endsubroutine init_uu
!***********************************************************************
    subroutine pencil_criteria_hydro()
!
!  All pencils that the Hydro module depends on are specified here.
!
!  20-11-04/anders: coded
!
      use Cdata
!
      if (idiag_urms/=0 .or. idiag_umax/=0 .or. idiag_u2m/=0 .or. &
          idiag_um2/=0) lpenc_diagnos(i_u2)=.true.
!
    endsubroutine pencil_criteria_hydro
!***********************************************************************
    subroutine pencil_interdep_hydro(lpencil_in)
!
!  Interdependency among pencils from the Hydro module is specified here
!
!  20-11-04/anders: coded
!
      logical, dimension (npencils) :: lpencil_in
!
      if (lpencil_in(i_u2)) lpencil_in(i_uu)=.true.
!
    endsubroutine pencil_interdep_hydro
!***********************************************************************
    subroutine calc_pencils_hydro(f,p)
!
!  Calculate Hydro pencils.
!  Most basic pencils should come first, as others may depend on them.
!
!   08-nov-04/tony: coded
!
      use Cdata
      use Sub, only: dot2_mn, sum_mn_name, max_mn_name, integrate_mn_name
      use Magnetic, only: ABC_A,ABC_B,ABC_C,kx_aa,ky_aa,kz_aa
!
      real, dimension (mx,my,mz,mvar+maux) :: f       
      type (pencil_case) :: p
!
      real, dimension(nx) :: kdotxwt
      integer :: modeN
!
      intent(in) :: f
      intent(inout) :: p
      if (kinflow=='ABC') then
! uu
        if (lpencil(i_uu)) then
          if (headtt) print*,'ABC flow'
          p%uu(:,1)=ABC_A*sin(kz_aa*z(n))    +ABC_C*cos(ky_aa*y(m))
          p%uu(:,2)=ABC_B*sin(kx_aa*x(l1:l2))+ABC_A*cos(kz_aa*z(n))
          p%uu(:,3)=ABC_C*sin(ky_aa*y(m))    +ABC_B*cos(kx_aa*x(l1:l2))
        endif 
! divu
        if (lpencil(i_divu)) p%divu=0. 
      elseif (kinflow=='roberts') then
! uu
        if (lpencil(i_uu)) then
          if (headtt) print*,'Glen Roberts flow; kx_aa,ky_aa=',kx_aa,ky_aa
          p%uu(:,1)=+sin(kx_aa*x(l1:l2))*cos(ky_aa*y(m))
          p%uu(:,2)=-cos(kx_aa*x(l1:l2))*sin(ky_aa*y(m))
          p%uu(:,3)=+sin(kx_aa*x(l1:l2))*sin(ky_aa*y(m))*sqrt(2.)
        endif 
! divu
        if (lpencil(i_divu)) p%divu= (kx_aa-ky_aa)*cos(kx_aa*x(l1:l2))*cos(ky_aa*y(m))
!
      elseif (kinflow=='poshel-roberts') then
        if (headtt) print*,'Pos Helicity Roberts flow; kx_aa,ky_aa=',kx_aa,ky_aa
        p%uu(:,1)=-cos(kx_aa*x(l1:l2))*sin(ky_aa*y(m))
        p%uu(:,2)=+sin(kx_aa*x(l1:l2))*cos(ky_aa*y(m))
        p%uu(:,3)=+cos(kx_aa*x(l1:l2))*cos(ky_aa*y(m))*sqrt(2.)
!
      elseif (kinflow=='KS') then
        p%uu=0.
        do modeN=1,KS_modes  ! sum over KS_modes modes
           kdotxwt=KS_k(1,modeN)*x(l1:l2)+(KS_k(2,modeN)*y(m)+KS_k(3,modeN)*z(n))+KS_omega(modeN)*t
           if (lpencil(i_uu)) then 
             p%uu(:,1) = p%uu(:,1) + cos(kdotxwt)*KS_A(1,modeN) + sin(kdotxwt)*KS_B(1,modeN)    
             p%uu(:,2) = p%uu(:,2) + cos(kdotxwt)*KS_A(2,modeN) + sin(kdotxwt)*KS_B(2,modeN)    
             p%uu(:,3) = p%uu(:,3) + cos(kdotxwt)*KS_A(3,modeN) + sin(kdotxwt)*KS_B(3,modeN)    
           endif
        enddo
        if (lpencil(i_divu))  p%divu = 0.
      else
! uu
        if (lpencil(i_uu)) then
          if (headtt) print*,'uu=0'
          p%uu=0.
        endif 
! divu
        if (lpencil(i_divu)) p%divu=0. 
      endif
! u2
      if (lpencil(i_u2)) call dot2_mn(p%uu,p%u2)
      if (idiag_ekin/=0 .or. idiag_ekintot/=0) then
        lpenc_diagnos(i_rho)=.true.
        lpenc_diagnos(i_u2)=.true.
      endif
!
!  Calculate maxima and rms values for diagnostic purposes
!
      if (ldiagnos) then
        if (idiag_urms/=0)  call sum_mn_name(p%u2,idiag_urms,lsqrt=.true.)
        if (idiag_umax/=0)  call max_mn_name(p%u2,idiag_umax,lsqrt=.true.)
        if (idiag_uzrms/=0) &
            call sum_mn_name(p%uu(:,3)**2,idiag_uzrms,lsqrt=.true.)
        if (idiag_uzmax/=0) &
            call max_mn_name(p%uu(:,3)**2,idiag_uzmax,lsqrt=.true.)
        if (idiag_u2m/=0)   call sum_mn_name(p%u2,idiag_u2m)
        if (idiag_um2/=0)   call max_mn_name(p%u2,idiag_um2)
!
        if (idiag_ekin/=0)  call sum_mn_name(.5*p%rho*p%u2,idiag_ekin)
        if (idiag_ekintot/=0) & 
            call integrate_mn_name(.5*p%rho*p%u2,idiag_ekintot)
      endif
!     
      if(NO_WARN) print*,f(1,1,1,1)   !(keep compiler quiet)
!
    endsubroutine calc_pencils_hydro
!***********************************************************************
    subroutine duu_dt(f,df,p)
!
!  velocity evolution, dummy routine
!
!   7-jun-02/axel: adapted from hydro
!
      use Cdata
      use Sub
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz,mvar) :: df
      type (pencil_case) :: p
!
      intent(in) :: f,df,p
!
!  uu/dx for timestep
!
      if (lfirst.and.ldt) advec_uu=abs(p%uu(:,1))*dx_1(l1:l2)+ &
                                   abs(p%uu(:,2))*dy_1(  m  )+ &
                                   abs(p%uu(:,3))*dz_1(  n  )
      if (headtt.or.ldebug) print*,'duu_dt: max(advec_uu) =',maxval(advec_uu)
!
      if(NO_WARN) print*, f, df     !(keep compiler quiet)
!
    endsubroutine duu_dt
!***********************************************************************
    subroutine random_isotropic_KS_setup(initpower,kmin,kmax)
!
!   produces random, isotropic field from energy spectrum following the
!   KS method (Malik and Vassilicos, 1999.)  
!
!   more to do; unsatisfactory so far - at least for a steep power-law energy spectrum 
!   
!   27-may-05/tony: modified from snod's KS hydro initial
!  
    use Cdata, only: pi,Lxyz
    use Sub    
    use General    
!  
    integer :: modeN

! how many wavenumbers? 
    real, dimension (3) :: k_unit
    real, dimension (3) :: vec,ee,e1,e2,field
    real, dimension (4) :: r
    real :: initpower,kmin,kmax,ps,k,phi,theta,alpha,beta,dk
    real :: ex,ey,ez,norm,kdotx,a,energy

    allocate(KS_k(3,KS_modes))
    allocate(KS_A(3,KS_modes))
    allocate(KS_B(3,KS_modes))
    allocate(KS_omega(KS_modes))
!
!    minlen=Lxyz(1)/(nx-1)
!    kmax=2.*pi/minlen
!    KS_modes=int(0.5*(nx-1))
!    hh=Lxyz(1)/(nx-1)
!    pta=(nx)**(1.0/(nx-1))
!    do modeN=1,KS_modes
!       ggt=(kkmax-kkmin)/(KS_modes-1)
!       ggt=(kkmax/kkmin)**(1./(KS_modes-1))
!        k(modeN)=kmin+(ggt*(modeN-1))
!        k(modeN)=(modeN+3)*2*pi/Lxyz(1)
!       k(modeN)=kkmin*(ggt**(modeN-1)
!    enddo
!
!    do modeN=1,KS_modes
!       if(modeN.eq.1)delk(modeN)=(k(modeN+1)-K(modeN))
!       if(modeN.eq.KS_modes)delk(modeN)=(k(modeN)-k(modeN-1))
!       if(modeN.gt.1.and.modeN.lt.KS_modes)delk(modeN)=(k(modeN+1)-k(modeN-2))/2.0
!    enddo
!          mk=(k2*k2)*((1.0 + (k2/(bk_min*bk_min)))**(0.5*initpower-2.0))
!
!  set kmin
!
       kmin=2.*pi/Lxyz(1)
!       kmin=kmin*2.*pi
       kmax=nx*pi
       a=(kmax/kmin)**(1./(KS_modes-1.))

!       
    do modeN=1,KS_modes  
!   
!  pick wavenumber
!
!       k=modeN*kmin
       k=kmin*(a**(modeN-1.))
!
!  calculate dk
!
!       print *,kmin,kmax,k
!       dk=1.0*kmin
       if(modeN==1)dk=kmin*(a-1.)/2
       if(modeN.gt.1.and.modeN.lt.KS_modes)dk=(a**(modeN-2))*kmin*((a**2) -1.)/2.
       if(modeN==KS_modes)dk=(a**(KS_modes -2.))*kmin*(a -1.)/2.

!      print *,dk  !this has been checked and the dks are exactly right!
!
!   pick 4 random angles for each mode
!         
       call random_number_wrapper(r); 
       theta=pi*(r(1) - 0.)  
       phi=pi*(2*r(2) - 0.)  
       alpha=pi*(2*r(3) - 0.)  
       beta=pi*(2*r(4) - 0.)
!       call random_number_wrapper(r); gamma(modeN)=pi*(2*r - 0.)  ! random phase?

!
!   make a random unit vector by rotating fixed vector to random position
 !   (alternatively make a random transformation matrix for each k)
!
       k_unit(1)=sin(theta)*cos(phi)
       k_unit(2)=sin(theta)*sin(phi)
       k_unit(3)=cos(theta)

!       energy=(((k/kmin)**2. +1.)**(-11./6.))*(k**2.)*exp(-0.5*(k/kmax)**2.)
       energy=(((k/1.)**2. +1.)**(-11./6.))*(k**2.)*exp(-0.5*(k/kmax)**2.)

!
!   make a vector KS_k of length k from the unit vector for each mode
!
       KS_k(:,modeN)=k*k_unit(:)
!       KS_omega(modeN)=k**(2./3.)
       KS_omega(modeN)=sqrt(energy*(k**3))
!
!   construct basis for plane having rr normal to it
!   (bit of code from forcing to construct x', y')
!
       if((k_unit(2).eq.0).and.(k_unit(3).eq.0)) then
        ex=0.; ey=1.; ez=0.           
       else
        ex=1.; ey=0.; ez=0.
       endif
       ee = (/ex, ey, ez/)
       call cross(k_unit(:),ee,e1)
       call dot2(e1,norm); e1=e1/sqrt(norm) ! e1: unit vector perp. to KS_k
       call cross(k_unit(:),e1,e2)
       call dot2(e2,norm); e2=e2/sqrt(norm) ! e2: unit vector perp. to KS_k, e1
!
!   make two random unit vectors KS_B and KS_A in the constructed plane
!
       KS_A(:,modeN) = cos(alpha)*e1 + sin(alpha)*e2
       KS_B(:,modeN) = cos(beta)*e1  + sin(beta)*e2
!
!   define the power spectrum (ps=sqrt(2.*power_spectrum(k)*delta_k/3.))
!
!       ps=(k**(initpower/2.))*sqrt(dk*2./3.)
       ps=sqrt(2.*energy*dk/3.0) !the factor of 2 just after the sqrt may need to be 2./3.
!
!   give KS_A and KS_B length ps
!   
       KS_A(:,modeN)=ps*KS_A(:,modeN)
       KS_B(:,modeN)=ps*KS_B(:,modeN)
!
!   form RA = RA x k_unit and RB = RB x k_unit 
!
       call cross(KS_A(:,modeN),k_unit(:),KS_A(:,modeN))
       call cross(KS_B(:,modeN),k_unit(:),KS_B(:,modeN))
!
     enddo
!
!
    endsubroutine random_isotropic_KS_setup
!***********************************************************************
    subroutine rprint_hydro(lreset,lwrite)
!
!  reads and registers print parameters relevant for hydro part
!
!   8-jun-02/axel: adapted from hydro
!
      use Cdata
      use Sub
!
      integer :: iname
      logical :: lreset,lwr
      logical, optional :: lwrite
!
      lwr = .false.
      if (present(lwrite)) lwr=lwrite
!
!  reset everything in case of reset
!  (this needs to be consistent with what is defined above!)
!
      if (lreset) then
        idiag_u2m=0; idiag_um2=0; idiag_oum=0; idiag_o2m=0
        idiag_uxpt=0; idiag_uypt=0; idiag_uzpt=0; idiag_dtu=0; idiag_dtv=0
        idiag_urms=0; idiag_umax=0; idiag_uzrms=0; idiag_uzmax=0;
        idiag_orms=0; idiag_omax=0; idiag_oumphi=0
        idiag_ruxm=0; idiag_ruym=0; idiag_ruzm=0; idiag_rumax=0
        idiag_ux2m=0; idiag_uy2m=0; idiag_uz2m=0
        idiag_uxuym=0; idiag_uxuzm=0; idiag_uyuzm=0
        idiag_umx=0; idiag_umy=0; idiag_umz=0
        idiag_Marms=0; idiag_Mamax=0; idiag_divu2m=0; idiag_epsK=0
        idiag_urmphi=0; idiag_upmphi=0; idiag_uzmphi=0; idiag_u2mphi=0
        idiag_ekin=0; idiag_ekintot=0
      endif
!
!  iname runs through all possible names that may be listed in print.in
!
      if(lroot.and.ip<14) print*,'run through parse list'
      do iname=1,nname
        call parse_name(iname,cname(iname),cform(iname),'ekin',idiag_ekin)
        call parse_name(iname,cname(iname),cform(iname),'ekintot',idiag_ekintot)
        call parse_name(iname,cname(iname),cform(iname),'u2m',idiag_u2m)
        call parse_name(iname,cname(iname),cform(iname),'um2',idiag_um2)
        call parse_name(iname,cname(iname),cform(iname),'o2m',idiag_o2m)
        call parse_name(iname,cname(iname),cform(iname),'oum',idiag_oum)
        call parse_name(iname,cname(iname),cform(iname),'dtu',idiag_dtu)
        call parse_name(iname,cname(iname),cform(iname),'dtv',idiag_dtv)
        call parse_name(iname,cname(iname),cform(iname),'urms',idiag_urms)
        call parse_name(iname,cname(iname),cform(iname),'umax',idiag_umax)
        call parse_name(iname,cname(iname),cform(iname),'uzrms',idiag_uzrms)
        call parse_name(iname,cname(iname),cform(iname),'uzmax',idiag_uzmax)
        call parse_name(iname,cname(iname),cform(iname),'ux2m',idiag_ux2m)
        call parse_name(iname,cname(iname),cform(iname),'uy2m',idiag_uy2m)
        call parse_name(iname,cname(iname),cform(iname),'uz2m',idiag_uz2m)
        call parse_name(iname,cname(iname),cform(iname),'uxuym',idiag_uxuym)
        call parse_name(iname,cname(iname),cform(iname),'uxuzm',idiag_uxuzm)
        call parse_name(iname,cname(iname),cform(iname),'uyuzm',idiag_uyuzm)
        call parse_name(iname,cname(iname),cform(iname),'orms',idiag_orms)
        call parse_name(iname,cname(iname),cform(iname),'omax',idiag_omax)
        call parse_name(iname,cname(iname),cform(iname),'ruxm',idiag_ruxm)
        call parse_name(iname,cname(iname),cform(iname),'ruym',idiag_ruym)
        call parse_name(iname,cname(iname),cform(iname),'ruzm',idiag_ruzm)
        call parse_name(iname,cname(iname),cform(iname),'rumax',idiag_rumax)
        call parse_name(iname,cname(iname),cform(iname),'umx',idiag_umx)
        call parse_name(iname,cname(iname),cform(iname),'umy',idiag_umy)
        call parse_name(iname,cname(iname),cform(iname),'umz',idiag_umz)
        call parse_name(iname,cname(iname),cform(iname),'Marms',idiag_Marms)
        call parse_name(iname,cname(iname),cform(iname),'Mamax',idiag_Mamax)
        call parse_name(iname,cname(iname),cform(iname),'divu2m',idiag_divu2m)
        call parse_name(iname,cname(iname),cform(iname),'epsK',idiag_epsK)
        call parse_name(iname,cname(iname),cform(iname),'uxpt',idiag_uxpt)
        call parse_name(iname,cname(iname),cform(iname),'uypt',idiag_uypt)
        call parse_name(iname,cname(iname),cform(iname),'uzpt',idiag_uzpt)
      enddo
!
!  write column where which hydro variable is stored
!
      if (lwr) then
        write(3,*) 'i_ekin=',idiag_ekin
        write(3,*) 'i_ekintot=',idiag_ekintot
        write(3,*) 'i_u2m=',idiag_u2m
        write(3,*) 'i_um2=',idiag_um2
        write(3,*) 'i_o2m=',idiag_o2m
        write(3,*) 'i_oum=',idiag_oum
        write(3,*) 'i_dtu=',idiag_dtu
        write(3,*) 'i_dtv=',idiag_dtv
        write(3,*) 'i_urms=',idiag_urms
        write(3,*) 'i_umax=',idiag_umax
        write(3,*) 'i_uzrms=',idiag_uzrms
        write(3,*) 'i_uzmax=',idiag_uzmax
        write(3,*) 'i_ux2m=',idiag_ux2m
        write(3,*) 'i_uy2m=',idiag_uy2m
        write(3,*) 'i_uz2m=',idiag_uz2m
        write(3,*) 'i_uxuym=',idiag_uxuym
        write(3,*) 'i_uxuzm=',idiag_uxuzm
        write(3,*) 'i_uyuzm=',idiag_uyuzm
        write(3,*) 'i_orms=',idiag_orms
        write(3,*) 'i_omax=',idiag_omax
        write(3,*) 'i_ruxm=',idiag_ruxm
        write(3,*) 'i_ruym=',idiag_ruym
        write(3,*) 'i_ruzm=',idiag_ruzm
        write(3,*) 'i_rumax=',idiag_rumax
        write(3,*) 'i_umx=',idiag_umx
        write(3,*) 'i_umy=',idiag_umy
        write(3,*) 'i_umz=',idiag_umz
        write(3,*) 'i_Marms=',idiag_Marms
        write(3,*) 'i_Mamax=',idiag_Mamax
        write(3,*) 'i_divu2m=',idiag_divu2m
        write(3,*) 'i_epsK=',idiag_epsK
        write(3,*) 'i_uxpt=',idiag_uxpt
        write(3,*) 'i_uypt=',idiag_uypt
        write(3,*) 'i_uzpt=',idiag_uzpt
        write(3,*) 'i_uxmz=',idiag_uxmz
        write(3,*) 'i_uymz=',idiag_uymz
        write(3,*) 'i_uzmz=',idiag_uzmz
        write(3,*) 'i_uxmxy=',idiag_uxmxy
        write(3,*) 'i_uymxy=',idiag_uymxy
        write(3,*) 'i_uzmxy=',idiag_uzmxy
        write(3,*) 'i_urmphi=',idiag_urmphi
        write(3,*) 'i_upmphi=',idiag_upmphi
        write(3,*) 'i_uzmphi=',idiag_uzmphi
        write(3,*) 'i_u2mphi=',idiag_u2mphi
        write(3,*) 'i_oumphi=',idiag_oumphi
        write(3,*) 'nname=',nname
        write(3,*) 'iuu=',iuu
        write(3,*) 'iux=',iux
        write(3,*) 'iuy=',iuy
        write(3,*) 'iuz=',iuz
      endif
!
    endsubroutine rprint_hydro
!***********************************************************************
    subroutine calc_mflow
!
!  dummy routine
!
!  19-jul-03/axel: adapted from hydro
!
    endsubroutine calc_mflow
!***********************************************************************
    subroutine calc_turbulence_pars(f)
!
!  dummy routine
!
!  18-may-04/anders: adapted from hydro
!
      real, dimension (mx,my,mz,mvar+maux) :: f
!
      if(NO_WARN) print*,f  !(keep compiler quiet)
!      
    endsubroutine calc_turbulence_pars
!***********************************************************************

endmodule Hydro
