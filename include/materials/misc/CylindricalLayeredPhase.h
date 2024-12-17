#pragma once

#include "Material.h"

class CylindricalLayeredPhase : public Material
{
public:
  static InputParameters validParams();

  CylindricalLayeredPhase(const InputParameters & parameters);

protected:
  void computeQpProperties() override;

  ADMaterialProperty<Real> & _phi;

  const std::vector<Real> _radii;
  const Real _w;
  const RealVectorValue _p;
  const RealVectorValue _v;
};
