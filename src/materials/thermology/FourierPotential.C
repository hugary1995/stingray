// Copyright 2023, UChicago Argonne, LLC All Rights Reserved
// License: L-GPL 3.0
#include "FourierPotential.h"

registerMooseObject("EelApp", FourierPotential);
registerMooseObject("EelApp", AnisotropicFourierPotential);

template <typename T>
InputParameters
FourierPotentialTempl<T>::validParams()
{
  InputParameters params = ThermalEnergyDensity::validParams();
  params.addClassDescription(params.getClassDescription() +
                             " This class defines the Fourier potential for heat conduction.");
  params.addRequiredParam<MaterialPropertyName>("thermal_conductivity",
                                                "The thermal conductivity tensor");
  return params;
}

template <typename T>
FourierPotentialTempl<T>::FourierPotentialTempl(const InputParameters & parameters)
  : ThermalEnergyDensity(parameters), _kappa(getADMaterialProperty<T>("thermal_conductivity"))
{
}

template <typename T>
void
FourierPotentialTempl<T>::computeQpProperties()
{
  auto grad_T = _grad_T[_qp];
  // if (getBlockCoordSystem() == Moose::COORD_RZ)
  //   grad_T(2) = _T[_qp] / _q_point[_qp](0);

  _d_H_d_grad_lnT[_qp] = _kappa[_qp] * _grad_T[_qp];
  _H[_qp] = 0.5 * _d_H_d_grad_lnT[_qp] * _grad_T[_qp] / _T[_qp];
}

template class FourierPotentialTempl<Real>;
template class FourierPotentialTempl<RankTwoTensor>;
