#include "KLSparsity.h"
#include "libmesh/elem.h"

using namespace libMesh;

void
KLSparsity::operator()(const MeshBase::const_element_iterator & range_begin,
                       const MeshBase::const_element_iterator & range_end,
                       processor_id_type p,
                       map_type & coupled_elements)
{
  const CouplingMatrix * const null_mat = nullptr;
  for (const auto & elem : as_range(range_begin, range_end))
  {
    coupled_elements.emplace(elem, null_mat);
    for (const auto & elem_remote : _mesh.active_element_ptr_range())
      coupled_elements.emplace(elem_remote, null_mat);
  }
}
