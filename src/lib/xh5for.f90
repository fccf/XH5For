module xh5for

use xdmf_utils
use xh5for_handler
use mpi_environment
use xh5for_parameters
use uniform_grid_descriptor
use spatial_grid_descriptor
use IR_Precision, only: I4P, I8P, str
use xh5for_contiguous_hyperslab_handler



implicit none

    type :: xh5for_t
    private
        integer(I4P)                         :: Strategy = XDMF_STRATEGY_CONTIGUOUS_HYPERSLAB
        type(mpi_env_t)                      :: MPIEnvironment
        type(uniform_grid_descriptor_t)      :: UniformGridDescriptor
        type(spatial_grid_descriptor_t)      :: SpatialGridDescriptor
        class(xh5for_handler_t), allocatable :: Handler
    contains
    private
        procedure         :: xh5for_Initialize_I4P
        procedure         :: xh5for_Initialize_I8P
        procedure         :: xh5for_WriteGeometry_I4P
        procedure         :: xh5for_WriteGeometry_I8P
        procedure         :: xh5for_WriteTopology_R4P
        procedure         :: xh5for_WriteTopology_R8P
        procedure         :: is_valid_Strategy     => xh5for_is_valid_strategy
        procedure, public :: SetStrategy           => xh5for_SetStrategy
        generic,   public :: Initialize            => xh5for_Initialize_I4P, &
                                                      xh5for_Initialize_I8P
        procedure, public :: Open                  => xh5for_Open
        procedure, public :: Close                 => xh5for_Close
        generic,   public :: WriteTopology         => xh5for_WriteTopology_R4P, &
                                                      xh5for_WriteTopology_R8P
        generic,   public :: WriteGeometry         => xh5for_WriteGeometry_I4P, &
                                                      xh5for_WriteGeometry_I8P
    end type xh5for_t

contains

    function xh5for_is_valid_strategy(this, Strategy) result(is_valid)
    !-----------------------------------------------------------------
    !< Return True if is a valid Strategy
    !----------------------------------------------------------------- 
        class(xh5for_t), intent(IN)  :: this
        integer(I4P),    intent(IN)  :: Strategy
        logical                      :: is_valid
        integer(I4P), allocatable    :: allowed_strategies(:)
    !----------------------------------------------------------------- 
        allowed_Strategies = (/XDMF_STRATEGY_CONTIGUOUS_HYPERSLAB/)
        is_valid = MINVAL(ABS(allowed_strategies - Strategy)) == 0_I4P
        if(.not. is_valid) call warning_message('Wrong Strategy: "'//trim(str(no_sign=.true., n=Strategy))//'"')
    end function xh5for_is_valid_strategy


    subroutine xh5for_SetStrategy(this, Strategy)
    !----------------------------------------------------------------- 
    !< Set the strategy of data handling
    !----------------------------------------------------------------- 
        class(xh5for_t), intent(INOUT)  :: this
        integer(I4P),    intent(IN)     :: Strategy
    !----------------------------------------------------------------- 
        if(this%is_valid_Strategy(Strategy)) this%Strategy = Strategy
    end subroutine xh5for_SetStrategy


    subroutine xh5for_Initialize_I4P(this, NumberOfNodes, NumberOfElements, TopologyType, GeometryType, comm, root)
    !----------------------------------------------------------------- 
    !< Apply strategy and initialize lightdata and heavydata handlers
    !----------------------------------------------------------------- 
        class(xh5for_t),   intent(INOUT)  :: this
        integer(I4P),      intent(IN)     :: NumberOfNodes    !< Number of nodes of the current grid (I4P)
        integer(I4P),      intent(IN)     :: NumberOfElements !< Number of elements of the current grid (I4P)
        integer(I4P),      intent(IN)     :: TopologyType     !< Topology type of the current grid
        integer(I4P),      intent(IN)     :: GeometryType     !< Geometry type of the current grid
        integer, optional, intent(IN)     :: comm
        integer, optional, intent(IN)     :: root
        integer                           :: error
        integer                           :: r_root = 0
    !----------------------------------------------------------------- 
        if(present(root)) r_root = root
! FREEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
        select case(this%Strategy)

            case (XDMF_STRATEGY_CONTIGUOUS_HYPERSLAB)
                allocate(xh5for_contiguous_hyperslab_handler_t::this%Handler)

            case default
                allocate(xh5for_contiguous_hyperslab_handler_t::this%Handler)
        end select 


        ! MPI environment initialization
        if(present(comm)) then
            call This%MPIEnvironment%Initialize(comm = comm, root = r_root, mpierror = error)
        else
            call This%MPIEnvironment%Initialize(root = r_root, mpierror = error)
        endif
        ! Uniform grid descriptor initialization
        call this%UniformGridDescriptor%Initialize(           &
                NumberOfNodes = int(NumberOfNodes,I8P),       &
                NumberOfElements = int(NumberOfElements,I8P), &
                TopologyType = TopologyType,                  &
                GeometryType = GeometryType)
        ! Spatial grid descriptor initialization
        call this%SpatialGridDescriptor%Initialize(            &
                MPIEnvironment = this%MPIEnvironment,          &
                NumberOfNodes = int(NumberOfNodes,I8P),        &
                NumberOfElements = int(NumberOfElements,I8P),  &
                TopologyType = TopologyType,                   &
                GeometryType = GeometryType)
        ! XH5For handler initialization
        call this%Handler%Initialize(                             &
                MPIEnvironment=this%MPIEnvironment,               &
                SpatialGridDescriptor=this%SpatialGridDescriptor, &
                UniformGridDescriptor=this%UniformGridDescriptor)

    end subroutine xh5for_Initialize_I4P


    subroutine xh5for_Initialize_I8P(this, NumberOfNodes, NumberOfElements, TopologyType, GeometryType, comm, root)
    !----------------------------------------------------------------- 
    !< Apply strategy and initialize lightdata and heavydata handlers
    !----------------------------------------------------------------- 
        class(xh5for_t),   intent(INOUT)  :: this
        integer(I8P),      intent(IN)     :: NumberOfNodes    !< Number of nodes of the current grid (I8P)
        integer(I8P),      intent(IN)     :: NumberOfElements !< Number of elements of the current grid (I8P)
        integer(I4P),      intent(IN)     :: TopologyType     !< Topology type of the current grid
        integer(I4P),      intent(IN)     :: GeometryType     !< Geometry type of the current grid
        integer, optional, intent(IN)     :: comm
        integer, optional, intent(IN)     :: root
        integer                           :: error
        integer                           :: r_root = 0
    !----------------------------------------------------------------- 
        if(present(root)) r_root = root
! FREEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE
        select case(this%Strategy)

            case (XDMF_STRATEGY_CONTIGUOUS_HYPERSLAB)
                allocate(xh5for_contiguous_hyperslab_handler_t::this%Handler)

            case default
                allocate(xh5for_contiguous_hyperslab_handler_t::this%Handler)
        end select 

        ! MPI environment initialization
        if(present(comm)) then
            call This%MPIEnvironment%Initialize(comm = comm, root = r_root, mpierror = error)
        else
            call This%MPIEnvironment%Initialize(root = r_root, mpierror = error)
        endif
        ! Uniform grid descriptor initialization
        call this%UniformGridDescriptor%Initialize(  &
                NumberOfNodes = NumberOfNodes,       &
                NumberOfElements = NumberOfElements, &
                TopologyType = TopologyType,         &
                GeometryType = GeometryType)
        ! Spatial grid descriptor initialization
        call this%SpatialGridDescriptor%Initialize(&
                MPIEnvironment = this%MPIEnvironment, &
                NumberOfNodes = NumberOfNodes,        &
                NumberOfElements = NumberOfElements,  &
                TopologyType = TopologyType,          &
                GeometryType = GeometryType)
        ! XH5For handler initialization
        call this%Handler%Initialize(                              &
                MPIEnvironment=this%MPIEnvironment,               &
                SpatialGridDescriptor=this%SpatialGridDescriptor, &
                UniformGridDescriptor=this%UniformGridDescriptor)
    end subroutine xh5for_Initialize_I8P


    subroutine xh5for_Open(this, fileprefix)
    !-----------------------------------------------------------------
    !< Open a XDMF and HDF5 files
    !----------------------------------------------------------------- 
        class(xh5for_t), intent(INOUT) :: this                        !< XDMF handler
        character(len=*),      intent(IN)    :: fileprefix            !< XDMF filename
    !-----------------------------------------------------------------
        call this%Handler%Open(fileprefix)
    end subroutine xh5for_Open


    subroutine xh5for_Close(this)
    !-----------------------------------------------------------------
    !< Open a XDMF and HDF5 files
    !----------------------------------------------------------------- 
        class(xh5for_t), intent(INOUT) :: this                        !< XDMF handler
    !-----------------------------------------------------------------
        call this%Handler%Close()
    end subroutine xh5for_Close


    subroutine xh5for_WriteGeometry_I4P(this, Connectivities)
    !----------------------------------------------------------------- 
    !< Set the strategy of data handling
    !----------------------------------------------------------------- 
        class(xh5for_t), intent(INOUT) :: this
        integer(I4P),    intent(IN)    :: Connectivities(:)
        call this%Handler%WriteGeometry(Connectivities = Connectivities)
    end subroutine xh5for_WriteGeometry_I4P

    subroutine xh5for_WriteGeometry_I8P(this, Connectivities)
    !----------------------------------------------------------------- 
    !< Set the strategy of data handling
    !----------------------------------------------------------------- 
        class(xh5for_t), intent(INOUT) :: this
        integer(I8P),    intent(IN)    :: Connectivities(:)
        call this%Handler%WriteGeometry(Connectivities = Connectivities)
    end subroutine xh5for_WriteGeometry_I8P


    subroutine xh5for_WriteTopology_R4P(this, Coordinates)
    !----------------------------------------------------------------- 
    !< Set the strategy of data handling
    !----------------------------------------------------------------- 
        class(xh5for_t), intent(INOUT) :: this
        real(R4P),       intent(IN)    :: Coordinates(:)
        call this%Handler%WriteTopology(Coordinates = Coordinates)
    end subroutine xh5for_WriteTopology_R4P


    subroutine xh5for_WriteTopology_R8P(this, Coordinates)
    !----------------------------------------------------------------- 
    !< Set the strategy of data handling
    !----------------------------------------------------------------- 
        class(xh5for_t), intent(INOUT) :: this
        real(R8P),       intent(IN)    :: Coordinates(:)
        call this%Handler%WriteTopology(Coordinates = Coordinates)
    end subroutine xh5for_WriteTopology_R8P

end module xh5for