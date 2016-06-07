program test_hdf5_rect_dpp_handler

use IR_Precision, only : I4P, I8P, R4P, R8P, str
use xh5for_parameters
use hdf5_structured_dataset_per_process_handler
use mpi_environment
use structured_spatial_grid_descriptor
use structured_uniform_grid_descriptor
#ifdef ENABLE_MPI
#ifdef MPI_MOD
  use mpi
#endif
#ifdef MPI_H
  include 'mpif.h'
#endif
#endif

implicit none

    type(mpi_env_t)                                                   :: mpienv
    type(structured_spatial_grid_descriptor_t)                        :: spatialgrid
    type(structured_uniform_grid_descriptor_t)                        :: uniformgrid
    type(hdf5_structured_dataset_per_process_handler_t)               :: heavydata
    real(R4P),    dimension(3)                                        :: Xpoints  = (/1,2,3/)
    real(R4P),    dimension(4)                                        :: Ypoints  = (/2,3,4,5/)
    real(R4P),    dimension(5)                                        :: Zpoints  = (/3,4,5,6,7/)
    real(R4P),    dimension(:), allocatable                           :: values  
    integer                                                           :: mpierr
    integer                                                           :: i


#if defined(MPI_MOD) || defined(MPI_H)
    call MPI_INIT(mpierr)
#endif

    values = (/(i,i=0,size(Xpoints)*size(Ypoints)*size(Zpoints))/)

    call mpienv%initialize()
    call spatialgrid%initialize(MPIEnvironment=mpienv, XDim=int(size(Xpoints),I8P), YDim=int(size(Ypoints),I8P), ZDim=int(size(Zpoints),I8P), GridType=XDMF_GRID_TYPE_RECTILINEAR)
    call uniformgrid%initialize(XDim=int(size(Xpoints),I8P), YDim=int(size(Ypoints),I8P), ZDim=int(size(Zpoints),I8P), GridType=XDMF_GRID_TYPE_RECTILINEAR)
    call heavydata%initialize(MPIEnvironment=mpienv, SpatialGridDescriptor=spatialgrid, UniformGridDescriptor=uniformgrid)
    call heavydata%OpenFile(action=XDMF_ACTION_WRITE, fileprefix='hdf5_rectilinear_dpp')
    call heavydata%WriteGeometry(X=Xpoints,Y=Ypoints,Z=Zpoints, Name='Coordinates')
    call heavydata%WriteAttribute(Name='solution', Center=XDMF_ATTRIBUTE_CENTER_NODE, Type=XDMF_ATTRIBUTE_TYPE_SCALAR, Values=values)
    call heavydata%CloseFile()
#ifdef ENABLE_MPI
    call MPI_FINALIZE(mpierr)
#endif


end program test_hdf5_rect_dpp_handler