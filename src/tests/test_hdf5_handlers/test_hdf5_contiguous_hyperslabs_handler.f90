program test_xdmf_hyperslabs_handler

use IR_Precision, only : I4P, I8P, R4P, R8P, str
use xh5for_parameters
use hdf5_contiguous_hyperslab_handler
use mpi_environment
use spatial_grid_descriptor
use uniform_grid_descriptor
#ifdef ENABLE_MPI
#ifdef MPI_MOD
  use mpi
#endif
#ifdef MPI_H
  include 'mpif.h'
#endif
#endif

implicit none

    type(mpi_env_t)                           :: mpienv
    type(spatial_grid_descriptor_t)           :: spatialgrid
    type(uniform_grid_descriptor_t)           :: uniformgrid
    type(hdf5_contiguous_hyperslab_handler_t) :: heavydata
    real(R8P), dimension(8)                   :: triangletopology = (/0.0,0.0, 1.0,0.0, 0.0,1.0, 1.1,1.1/)
    integer(I4P), dimension(6)                :: trianglegeometry = (/0,1,2,1,2,3/)
    integer         :: mpierr, i

#ifdef ENABLE_MPI
    call MPI_INIT(mpierr)
#endif
    call mpienv%initialize()
    call spatialgrid%initialize(MPIEnvironment=mpienv, NumberOfNodes=4_I8P, NumberOfElements=2_I8P, TopologyType=XDMF_TOPOLOGY_TYPE_TRIANGLE, GeometryType=XDMF_GEOMETRY_TYPE_XY)
    call uniformgrid%initialize(NumberOfNodes=4_I8P, NumberOfElements=2_I8P, TopologyType=XDMF_TOPOLOGY_TYPE_TRIANGLE, GeometryType=XDMF_GEOMETRY_TYPE_XY)
    call heavydata%initialize(MPIEnvironment=mpienv, SpatialGridDescriptor=spatialgrid, UniformGridDescriptor=uniformgrid)
    call heavydata%OpenFile('hyperslab.h5')
    call heavydata%WriteTopology(triangletopology+mpienv%get_rank())
    call heavydata%WriteGeometry(trianglegeometry)
!    call lightdata%WriteAttribute(Name='solution', Center=XDMF_ATTRIBUTE_CENTER_NODE, Type=XDMF_ATTRIBUTE_TYPE_SCALAR, GridID=i)
    call heavydata%CloseFile()
#ifdef ENABLE_MPI
    call MPI_FINALIZE(mpierr)
#endif


end program test_xdmf_hyperslabs_handler