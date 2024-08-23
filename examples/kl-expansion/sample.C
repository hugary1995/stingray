#include "libmesh/libmesh.h"
#include "libmesh/mesh.h"
#include "libmesh/exodusII_io.h"
#include "libmesh/exodusII_io_helper.h"

#include <boost/math/distributions.hpp>
#include <ctime>
#include <random>

#include "Eigen/Core"
#include "Eigen/Dense"

// Bring in everything from the libMesh namespace
using namespace libMesh;

struct MarginalGammaField
{
  MarginalGammaField(const std::vector<Real> & _xi, Real mean, Real cv) : xi(_xi)
  {
    auto std = cv * mean;
    auto var = std * std;
    theta = var / mean;
    k = mean / theta;
  }

  // Gaussian field
  std::vector<Real> xi;

  // Gamma distribution parameters
  Real theta;
  Real k;
};

std::vector<Real> sample_gaussian(const std::vector<Real> & eigvals,
                                  const std::vector<std::map<dof_id_type, Real>> & eigvecs,
                                  std::default_random_engine & generator);

std::vector<std::vector<Real>>
compute_correlated_Gamma_fields(const std::vector<MarginalGammaField> & fields,
                                const Eigen::MatrixXd & C);

int
main(int argc, char ** argv)
{
  // Check for proper usage.
  if (argc != 2)
    libmesh_error_msg("\nUsage: " << argv[0] << " 0.5");

  // Initialize libMesh and the dependent libraries.
  LibMeshInit init(argc, argv);

  if (init.comm().size() > 1)
    libmesh_error_msg("Parallel sampling is not supported, use 1 processor only.");

  // Read the mesh
  Mesh mesh(init.comm());
  mesh.read("basis.e");

  // Read the eigenpairs
  std::vector<Real> eigvals;
  std::vector<std::map<dof_id_type, Real>> eigvecs;

  ExodusII_IO basis(mesh);
  basis.read("basis.e");
  ExodusII_IO_Helper & basis_helper = basis.get_exio_helper();
  for (int i = 1; i < basis.get_num_time_steps(); i++)
  {
    // read eigenvalue
    std::vector<Real> eigval;
    basis.read_global_variable({"d"}, i, eigval);
    eigvals.push_back(eigval[0]);

    // read eigenvector
    basis_helper.read_nodal_var_values("v", i);
    eigvecs.push_back(basis_helper.nodal_var_values);
  }

  // random fields
  std::default_random_engine generator;
  generator.seed(std::time(NULL));
  MarginalGammaField E(sample_gaussian(eigvals, eigvecs, generator), 5e4, 0.05);
  MarginalGammaField si(sample_gaussian(eigvals, eigvecs, generator), 0.0023, 0.05);
  MarginalGammaField se(sample_gaussian(eigvals, eigvecs, generator), 0.02, 0.05);

  Eigen::MatrixXd C(3, 3);
  Real rho = std::stod(argv[1]);
  C << 1, rho, 0, rho, 1, 0, 0, 0, 1;

  auto P = compute_correlated_Gamma_fields({E, si, se}, C);

  // write random field
  ExodusII_IO fields(mesh);
  fields.write("fields.e");
  ExodusII_IO_Helper & fields_helper = fields.get_exio_helper();
  fields_helper.initialize_nodal_variables({"E", "si", "se"});
  fields_helper.write_nodal_values(1, P[0], 1);
  fields_helper.write_nodal_values(2, P[1], 1);
  fields_helper.write_nodal_values(3, P[2], 1);

  return EXIT_SUCCESS;
}

std::vector<Real>
sample_gaussian(const std::vector<Real> & eigvals,
                const std::vector<std::map<dof_id_type, Real>> & eigvecs,
                std::default_random_engine & generator)
{
  unsigned int ndof = eigvecs[0].size();
  std::vector<Real> Xi(ndof);
  std::normal_distribution<Real> distribution(0.0, 1.0);

  for (unsigned int i = 0; i < eigvals.size(); i++)
  {
    Real eta = distribution(generator);
    for (unsigned int j = 0; j < ndof; j++)
      Xi[j] += std::sqrt(eigvals[i]) * eta * eigvecs[i].at(j);
  }

  return Xi;
}

std::vector<std::vector<Real>>
compute_correlated_Gamma_fields(const std::vector<MarginalGammaField> & fields,
                                const Eigen::MatrixXd & C)
{
  if (C.rows() != C.cols())
    libmesh_error_msg("The covariance matrix must be square");
  if (fields.size() != C.rows())
    libmesh_error_msg("The covariance matrix is incompatible with the number of fields");

  Eigen::MatrixXd L = C.llt().matrixL();

  unsigned int ndof = fields[0].xi.size();

  // Normal distribution
  auto normal = boost::math::normal_distribution<Real>(0, 1);

  // Transform
  std::vector<std::vector<Real>> P(fields.size());
  for (unsigned int i = 0; i < fields.size(); i++)
  {
    P[i].resize(ndof);
    for (unsigned int j = 0; j < ndof; j++)
    {
      Real x = 0;
      for (unsigned int k = 0; k < fields.size(); k++)
        x += L(i, k) * fields[k].xi[j];
      P[i][j] = fields[i].theta *
                boost::math::gamma_p_inv<Real, Real>(fields[i].k, boost::math::cdf(normal, x));
    }
  }

  return P;
}
