#pragma once

#include "ChemicalEnergyDensity.h"

/**
 * This class defines the Fick's first law
 */
class FicksFirstLaw : public ChemicalEnergyDensity
{
public:
  static InputParameters validParams();

  FicksFirstLaw(const InputParameters & parameters);

protected:
  virtual ADReal computeQpChemicalEnergyDensity() const override;
  virtual ADReal computeQpDChemicalEnergyDensityDConcentration() override;
  virtual ADRealVectorValue computeQpDChemicalEnergyDensityDConcentrationGradient() override;
  virtual ADRankTwoTensor computeQpDChemicalEnergyDensityDDeformationGradient() override;

  /// The diffusion coefficient
  const ADMaterialProperty<RankTwoTensor> & _D;

  /// The mass transport viscosity
  const ADMaterialProperty<Real> & _eta;

  /// Ideal gas constant
  const Real _R;

  /// Temperature
  const ADVariableValue & _T;

  /// The molar volume of this species;
  const Real _Omega;
};
