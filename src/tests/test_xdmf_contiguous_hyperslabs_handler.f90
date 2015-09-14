program test_xdmf_hyperslabs_handler

use IR_Precision, only : I4P, I8P, R4P, R8P, str
use xh5for_parameters
use Fox_xdmf
use xdmf_contiguous_hyperslab_handler
use distributed_data_handler
#ifdef MPI_MOD
  use mpi
#endif
#ifdef MPI_H
  include 'mpif.h'
#endif

implicit none

    type(distributed_data_handler_t) :: distributeddata
    type(xdmf_contiguous_hyperslab_handler_t) :: lightdata
    integer         :: mpierr, i

#if defined(MPI_MOD) || defined(MPI_H)
    call MPI_INIT(mpierr)
#endif
    call distributeddata%initialize(NumberOfNodes=100_I8P, NumberOfElements=50_I8P, TopologyType=XDMF_TOPOLOGY_TYPE_TRIANGLE, GeometryType=XDMF_GEOMETRY_TYPE_XYZ)
    call lightdata%initialize(DistributedDataHandler=distributeddata, NumberOfNodes=100_I8P, NumberOfElements=50_I8P, TopologyType=XDMF_TOPOLOGY_TYPE_TRIANGLE, GeometryType=XDMF_GEOMETRY_TYPE_XYZ)
    call lightdata%OpenFile('hyperslab.xmf')
    do i=1, distributeddata%get_comm_size()
        call lightdata%WriteTopology(GridNumber=i)
        call lightdata%WriteGeometry(GridNumber=i)
        call lightdata%WriteAttribute(Name='solution', Center=XDMF_ATTRIBUTE_CENTER_NODE, Type=XDMF_ATTRIBUTE_TYPE_SCALAR, GridNumber=i)
    enddo
    call lightdata%CloseFile()
#if defined(MPI_MOD) || defined(MPI_H)
    call MPI_FINALIZE(mpierr)
#endif


end program test_xdmf_hyperslabs_handler