program xh5for_ch_regular_grid

use xh5for
#ifdef ENABLE_MPI
#ifdef MPI_MOD
  use mpi
#else
  include 'mpif.h'
#endif
#endif

implicit none
    !-----------------------------------------------------------------
    !< Variable definition
    !----------------------------------------------------------------- 
    type(xh5for_t)             :: xh5
    real(R4P),    dimension(3) :: Origin = (/0,0,0/)
    real(R4P),    dimension(3) :: DxDyDz = (/0.1,0.2,0.5/)
    integer(I4P), dimension(3) :: GridShape = (/11, 6, 3/)
    integer(I4P), dimension(3) :: NewGridShape
    integer(I4P), allocatable  :: scalartempI4P(:)
    real(R8P),    allocatable  :: scalartempR8P(:)
    real(R4P),    allocatable  :: out_Origin(:)
    real(R4P),    allocatable  :: out_DxDyDz(:)
    integer(I4P), allocatable  :: out_scalartempI4P(:)
    real(R8P),    allocatable  :: out_scalartempR8P(:)

    integer                    :: i, j
    integer                    :: rank = 0
    integer                    :: mpierr
    integer                    :: exitcode = 0

    real(R8P)                  :: time = 0.0
    integer                    :: num_steps = 5


    !-----------------------------------------------------------------
    !< Main program
    !----------------------------------------------------------------- 

#ifdef ENABLE_MPI
    call MPI_INIT(mpierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, mpierr);
#endif

    !< Write XDMF/HDF5 file
    call xh5%Open(FilePrefix='xh5for_ch_regular_grid_series', GridType=XDMF_GRID_TYPE_REGULAR, Strategy=XDMF_STRATEGY_CONTIGUOUS_HYPERSLAB, Action=XDMF_ACTION_WRITE)

    do i=1, num_steps
        !< Initialize some values depending on the mpi rank and step
        Origin = Origin + rank
        NewGridShape = GridShape*i
        allocate(scalartempI4P((NewGridShape(1))*(NewGridShape(2))*(NewGridShape(3))))
        scalartempI4P(:) = rank+i!(/(j,j=1,size(scalartempI4P))/)
        allocate(scalartempR8P((NewGridShape(1)-1)*(NEwGridShape(2)-1)*(NewGridShape(3)-1)*i))
        scalartempR8P(:) = rank+i!(/(real(j+rank),j=size(scalartempR8P),1,-1)/)
        time = time + 1

        call xh5%SetMesh(GridShape = NewGridShape)
        call xh5%AppendStep(Value=time)
        call xh5%WriteGeometry(Origin=Origin, DxDyDz=DxDyDz)
        call xh5%WriteAttribute(Name='Temperature_I4P', Type=XDMF_ATTRIBUTE_TYPE_SCALAR ,Center=XDMF_ATTRIBUTE_CENTER_NODE , Values=scalartempI4P)
        call xh5%WriteAttribute(Name='Temperature_R8P', Type=XDMF_ATTRIBUTE_TYPE_SCALAR ,Center=XDMF_ATTRIBUTE_CENTER_CELL , Values=scalartempR8P)
        call xh5%Serialize()
        deallocate(scalartempI4P)
        deallocate(scalartempR8P)
    enddo

    call xh5%Close()
    call xh5%Free()
    !< Read XDMF/HDF5 file
    call xh5%Open(FilePrefix='xh5for_ch_regular_grid_series', GridType=XDMF_GRID_TYPE_REGULAR, Strategy=XDMF_STRATEGY_CONTIGUOUS_HYPERSLAB, Action=XDMF_ACTION_READ)
    call xh5%Parse()

    do i=1, xh5%GetNumberOfSteps()
        call xh5%ReadGeometry(Origin=out_Origin, DxDyDz=out_DxDyDz)
        call xh5%ReadAttribute(Name='Temperature_I4P', Type=XDMF_ATTRIBUTE_TYPE_SCALAR ,Center=XDMF_ATTRIBUTE_CENTER_NODE , Values=out_scalartempI4P)
        call xh5%ReadAttribute(Name='Temperature_R8P', Type=XDMF_ATTRIBUTE_TYPE_SCALAR ,Center=XDMF_ATTRIBUTE_CENTER_CELL , Values=out_scalartempR8P)
        call xh5%NextStep()

#ifdef ENABLE_HDF5
        !< Check results
        if(.not. (sum(out_Origin - Origin)<=epsilon(0._R4P))) exitcode = -1
        if(.not. (sum(out_DxDyDz - DxDyDz)<=epsilon(0._R4P))) exitcode = -1
        if(.not. (sum(out_scalarTempI4P - (rank+i))==0)) exitcode = -1 !I8P not supported in HDF5 layer
        if(.not. (sum(out_scalartempR8P - (rank+i))<=epsilon(0._R4P))) exitcode = -1
#else
        if(rank==0) write(*,*) 'Warning: HDF5 is not enabled. Please enable HDF5 and recompile to write the HeavyData'
#endif
    enddo

    call xh5%Close()
    call xh5%Free()


#ifdef ENABLE_MPI
    call MPI_FINALIZE(mpierr)
#endif

    call exit( status=exitcode)
end program xh5for_ch_regular_grid