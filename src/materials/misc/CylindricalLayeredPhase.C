#include "CylindricalLayeredPhase.h"

registerMooseObject("EelApp", CylindricalLayeredPhase);

InputParameters
CylindricalLayeredPhase::validParams()
{
  InputParameters params = Material::validParams();
  params.addRequiredParam<MaterialPropertyName>("phase", "The name of the phase variable");
  params.addRequiredParam<std::vector<Real>>("radii", "Radii of the cylindrical layers");
  params.addRequiredParam<Real>("width", "Width of the phase");
  params.addParam<RealVectorValue>(
      "origin", RealVectorValue(0, 0, 0), "Origin of the cylindrical layers centerline");
  params.addParam<RealVectorValue>(
      "axis", RealVectorValue(0, 0, 1), "Axis direction of the cylindrical layers centerline");
  return params;
}

CylindricalLayeredPhase::CylindricalLayeredPhase(const InputParameters & parameters)
  : Material(parameters),
    _phi(declareADProperty<Real>("phase")),
    _radii(getParam<std::vector<Real>>("radii")),
    _w(getParam<Real>("width")),
    _p(getParam<RealVectorValue>("origin")),
    _v(getParam<RealVectorValue>("axis").unit())
{
}

void
CylindricalLayeredPhase::computeQpProperties()
{
  const auto d = _q_point[_qp] - _p;
  const auto r = (d - (d * _v) * _v).norm();

  auto dist = std::numeric_limits<Real>::max();
  for (const auto & radius : _radii)
  {
    const auto dist_to_layer = std::abs(r - radius);
    if (dist_to_layer < dist)
      dist = dist_to_layer;
  }

  _phi[_qp] = dist < 0.5 * _w ? (1 - dist / _w * 2) : 0.0;
}
