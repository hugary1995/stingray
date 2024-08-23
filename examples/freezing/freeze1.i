vf_si = 0.5 # initial silicon volume fraction
vf_sic = '${fparse 1-vf_si}'

rho_sic = 3.21e3 # kg/m^3, density
rho_si = 2.45e3 # kg/m^3
rho = '${fparse vf_si*rho_si+vf_sic+rho_sic}'

cp_sic = 750 # J/kg-K, specific heat
kappa = 130 # W/m-K, thermal conductivity
E_sic = 3.4e11 # Pa, Young's modulus
nu_sic = 0.36 # Poisson's ratio

alpha_sic = 2.25e-6 # 1/C, thermal expansion coefficient
alpha_si = 1.3e-6 # 1/C, thermal expansion coefficient

L_si = 1.8e6 # J/kg, specific latent heat
L = '${fparse vf_si*rho_si*L_si/(vf_si*rho_si+vf_sic*rho_sic)}'

Tm = '${fparse 1414+273.15}' # K, melting temperature
T0 = '${fparse Tm+50}' # K, initial temperature
cr = 2 # K/min, cooling rate
ct = '${fparse (Tm-300)/cr*60}' # s, total cooling time
dT = 8 # K, phase transition temperature range

kB = 5.67e-8 # Stefan Boltzmann constant
F = 0.6 # View factor

dt0 = 100
dtmax = 500
tend = '${fparse 20*3600}' # 20 hours

W = 250

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = 'gold/2D.msh'
  []
  [bottom1]
    type = SideSetsFromBoundingBoxGenerator
    input = fmg
    bottom_left = '0 0 0'
    top_right = '${fparse W/3} 10 0'
    boundary_new = 'bottom1'
    included_boundaries = 'bottom'
  []
  [bottom2]
    type = SideSetsFromBoundingBoxGenerator
    input = bottom1
    bottom_left = '${fparse W/3} 0 0'
    top_right = '${fparse W*2/3} 10 0'
    boundary_new = 'bottom2'
    included_boundaries = 'bottom'
  []
  [bottom3]
    type = SideSetsFromBoundingBoxGenerator
    input = bottom2
    bottom_left = '${fparse W*2/3} 0 0'
    top_right = '${W} 10 0'
    boundary_new = 'bottom3'
    included_boundaries = 'bottom'
  []
  [pin_x]
    type = ExtraNodesetGenerator
    input = bottom3
    new_boundary = 'pin_x'
    nodes = '3260'
  []
  [scale]
    type = TransformGenerator
    input = pin_x
    transform = SCALE
    vector_value = '1e-3 1e-3 1e-3'
  []
  use_displaced_mesh = false
[]

[Variables]
  [disp_x]
  []
  [disp_y]
  []
  [T]
    initial_condition = ${T0}
  []
[]

[AuxVariables]
  [phase]
    order = CONSTANT
    family = MONOMIAL
    [AuxKernel]
      type = ADMaterialRealAux
      property = phi
      execute_on = 'INITIAL TIMESTEP_END'
    []
  []
  [stress]
    order = CONSTANT
    family = MONOMIAL
    [AuxKernel]
      type = ADRankTwoScalarAux
      rank_two_tensor = stress
      scalar_type = MaxPrincipal
      execute_on = 'INITIAL TIMESTEP_END'
    []
  []
[]

[Functions]
  [T_furnace]
    type = PiecewiseLinear
    x = '0 ${ct}'
    y = '${T0} 300'
  []
  [alpha_pt]
    type = PiecewiseLinear
    x = '${fparse Tm-dT} ${Tm}'
    y = '0.0515 0'
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        strain = SMALL
        new_system = false
        use_automatic_differentiation = true
        incremental = false
        volumetric_locking_correction = true
        eigenstrain_names = 'eg_th_sic eg_th_si eg_pt'
        temperature = T
      []
    []
  []
[]

[Kernels]
  [htime]
    type = ADHeatConductionTimeDerivative
    variable = T
    density_name = rho
    specific_heat = cp
  []
  [hcond]
    type = ADHeatConduction
    variable = T
    thermal_conductivity = kappa
  []
[]

[BCs]
  [radiation]
    type = ADMatNeumannBC
    variable = T
    boundary = 'left right top bottom1 bottom3'
    value = -1
    boundary_material = qrad
  []
  [cool]
    type = FunctionDirichletBC
    variable = T
    boundary = 'bottom2'
    function = 'T_furnace'
  []
  [bottom_x]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'pin_x'
  []
  [bottom_y]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'bottom'
  []
[]

[Materials]
  # Thermal
  [phase_change]
    type = TwoPhaseChange
    latent_specific_heat = cpL_si
    temperature = T
    phase = phi
    starting_temperature = ${Tm}
    ending_temperature = '${fparse Tm-dT}'
    latent_heat = ${L}
  []
  [density]
    type = ADGenericConstantMaterial
    prop_names = 'rho'
    prop_values = '${rho}'
  []
  [specific_heat]
    type = ADParsedMaterial
    property_name = 'cp'
    expression = '${cp_sic}+cpL_si'
    material_property_names = 'cpL_si'
  []
  [conductivity]
    type = ADGenericConstantMaterial
    prop_names = 'kappa'
    prop_values = '${kappa}'
  []
  # flux for BCs
  [furnace_temperature]
    type = ADGenericFunctionMaterial
    prop_names = 'Tf'
    prop_values = 'T_furnace'
    constant_on = SUBDOMAIN
  []
  [qrad]
    type = ADParsedMaterial
    property_name = qrad
    expression = 'kB*F*(T^4-Tf^4)'
    coupled_variables = 'T'
    constant_names = 'kB F'
    constant_expressions = '${kB} ${F}'
    material_property_names = 'Tf'
    boundary = 'left right top bottom1 bottom3'
  []
  # Mechanics
  [thermal_eigenstrain_sic]
    type = ADComputeThermalExpansionEigenstrain
    eigenstrain_name = eg_th_sic
    thermal_expansion_coeff = ${alpha_sic}
    stress_free_temperature = 300
    temperature = T
  []
  [thermal_eigenstrain_si]
    type = ADComputeThermalExpansionEigenstrain
    eigenstrain_name = eg_th_si
    thermal_expansion_coeff = ${alpha_si}
    stress_free_temperature = ${T0}
    temperature = T
  []
  [phase_transformation_eigenstrain]
    type = ADComputeDilatationThermalExpansionFunctionEigenstrain
    eigenstrain_name = eg_pt
    dilatation_function = 'alpha_pt'
    stress_free_temperature = ${T0}
    temperature = T
  []
  [C]
    type = ADComputeVariableIsotropicElasticityTensor
    youngs_modulus = ${E_sic}
    poissons_ratio = ${nu_sic}
  []
  [stress]
    type = ADComputeLinearElasticStress
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON

  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  line_search = none

  automatic_scaling = true
  reuse_preconditioner = true
  reuse_preconditioner_max_linear_its = 25

  end_time = ${tend}
  dtmax = ${dtmax}
  dtmin = 1e-3
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = ${dt0}
    cutback_factor = 0.2
    cutback_factor_at_failure = 0.1
    growth_factor = 1.2
    optimal_iterations = 7
    iteration_window = 2
    linear_iteration_ratio = 100000
  []
  [Predictor]
    type = SimplePredictor
    scale = 1
    skip_after_failed_timestep = true
  []

  nl_abs_tol = 1e-8
  nl_rel_tol = 1e-6
  nl_max_its = 12

  l_max_its = 100
  l_tol = 1e-06
[]

[Outputs]
  exodus = true
  print_linear_residuals = false
[]
