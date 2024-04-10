I = 0.000006 #mA
width = 0.05 #mm
in = '${fparse I/width}'
t0 = 60
dtmax = 60

sigma_i_cam = 0.0005 #mS/mm
sigma_i_sse = 0.0023 #mS/mm
sigma_e_sse = 0.02 #mS/mm

c0 = 1e-4 #mmol/mm^3
cmax = 1e-3 #mmol/mm^3
c_ref_entropy = 5e-5
D_cam = 5e-5 #mm^2/s
D_sse = 1e-4 #mm^2/s

R = 8.3145 #mJ/mmol/K
T0 = 300 #K
F = 96485 #mC/mmol

i0 = 1e-1 #mA/mm^2
Phi_penalty = 10

[GlobalParams]
  energy_densities = 'dot(psi_c) q q_e zeta'
[]

[Mesh]
  [cathode]
    type = FileMeshGenerator
    file = 'gold/cathode.msh'
  []
  [interfaces]
    type = BreakMeshByBlockGenerator
    input = cathode
    add_interface_on_two_sides = true
    split_interface = true
  []
  use_displaced_mesh = false
[]

[Variables]
  [Phi_e]
    block = 'SSE'
  []
  [Phi]
  []
  [c]
  []
[]

[AuxVariables]
  [c_ref]
  []
  [T]
    initial_condition = ${T0}
  []
  [T_ref]
    initial_condition = ${T0}
  []
[]

[ICs]
  [c_sse]
    type = ConstantIC
    variable = c
    value = ${c0}
    block = 'SSE'
  []
  [c_cam]
    type = ConstantIC
    variable = c
    value = ${cmax}
    block = 'CAM'
  []
  [c_ref_sse]
    type = ConstantIC
    variable = c_ref
    value = ${c0}
    block = 'SSE'
  []
  [c_ref_cam]
    type = ConstantIC
    variable = c_ref
    value = ${c0}
    block = 'CAM'
  []
[]

[Kernels]
  # Charge balance
  [charge_balance_e]
    type = RankOneDivergence
    variable = Phi_e
    vector = i_e
    block = 'SSE'
  []
  [charge_balance]
    type = RankOneDivergence
    variable = Phi
    vector = i
  []
  # Mass balance
  [mass_balance_1]
    type = TimeDerivative
    variable = c
  []
  [mass_balance_2]
    type = RankOneDivergence
    variable = c
    vector = j
  []
[]

[InterfaceKernels]
  [current]
    type = MaterialInterfaceNeumannBC
    variable = Phi
    neighbor_var = Phi
    prop = ie
    factor = -1
    factor_neighbor = 1
    boundary = 'CAM_SSE'
  []
  [mass]
    type = MaterialInterfaceNeumannBC
    variable = c
    neighbor_var = c
    prop = je
    factor = -1
    factor_neighbor = 1
    boundary = 'CAM_SSE'
  []
  [continuity_Phi]
    type = InterfaceContinuity
    variable = Phi
    neighbor_var = Phi_e
    penalty = ${Phi_penalty}
    boundary = 'CAM_SSE'
  []
[]

[Functions]
  [in]
    type = PiecewiseLinear
    x = '0 ${t0}'
    y = '0 ${in}'
  []
[]

[BCs]
  [current]
    type = FunctionNeumannBC
    variable = Phi_e
    boundary = right
    function = in
  []
  [potential]
    type = DirichletBC
    variable = Phi
    boundary = left
    value = 0
  []
[]

[Materials]
  # Electrodynamics
  [conductivity]
    type = ADPiecewiseConstantByBlockMaterial
    prop_name = 'sigma'
    subdomain_to_prop_value = 'CAM ${sigma_i_cam} SSE ${sigma_i_sse}'
  []
  [conductivity_e]
    type = ADPiecewiseConstantByBlockMaterial
    prop_name = 'sigma_e'
    subdomain_to_prop_value = 'SSE ${sigma_e_sse}'
    block = 'SSE'
  []
  [charge_transport]
    type = BulkChargeTransport
    electrical_energy_density = q
    electric_potential = Phi
    electric_conductivity = sigma
    temperature = T
  []
  [charge_transport_e]
    type = BulkChargeTransport
    electrical_energy_density = q_e
    electric_potential = Phi_e
    electric_conductivity = sigma_e
    temperature = T
    block = 'SSE'
  []
  [current_density]
    type = CurrentDensity
    current_density = i
    electric_potential = Phi
  []
  [current_density_e]
    type = CurrentDensity
    current_density = i_e
    electric_potential = Phi_e
    block = 'SSE'
  []
  # Chemical reactions
  [diffusivity]
    type = ADPiecewiseConstantByBlockMaterial
    prop_name = 'D'
    subdomain_to_prop_value = 'CAM ${D_cam} SSE ${D_sse}'
  []
  [mobility]
    type = ADParsedMaterial
    f_name = M
    args = 'c_ref T_ref'
    material_property_names = 'D'
    function = 'D*c_ref/${R}/T_ref'
  []
  [chemical_energy]
    type = EntropicChemicalEnergyDensity
    chemical_energy_density = psi_c
    concentration = c
    ideal_gas_constant = ${R}
    temperature = T_ref
    reference_concentration = ${c_ref_entropy}
    reference_chemical_potential = 0
  []
  [chemical_potential]
    type = ChemicalPotential
    chemical_potential = mu
    concentration = c
  []
  [diffusion]
    type = MassDiffusion
    dual_chemical_energy_density = zeta
    chemical_potential = mu
    mobility = M
  []
  [mass_flux]
    type = MassFlux
    mass_flux = j
    chemical_potential = mu
  []

  # Redox
  [ramp]
    type = ADGenericFunctionMaterial
    prop_names = 'ramp'
    prop_values = 'if(t<${t0},t/${t0},1)'
    boundary = 'CAM_SSE'
  []
  [OCP_cathode_NMC811]
    type = ADParsedMaterial
    f_name = U
    # function = 'x:=c/${cmax}; (2.77e-4*x^2-0.0069*x+0.0785)*ramp'
    function = 'x:=c/${cmax}; (6.0826-6.9922*x+7.1062*x^2-5.4549e-5*exp(124.23*x-114.2593)-2.5947*x^3)*ramp'
    args = c
    material_property_names = 'ramp'
    boundary = 'CAM_SSE'
  []
  [charge_transfer_cathode_elyte]
    type = ChargeTransferReaction
    charge_transfer_current_density = ie
    charge_transfer_mass_flux = je
    charge_transfer_heat_flux = he
    electric_potential = Phi
    neighbor_electric_potential = Phi
    charge_transfer_coefficient = 0.5
    exchange_current_density = ${i0}
    faraday_constant = ${F}
    ideal_gas_constant = ${R}
    temperature = T
    open_circuit_potential = U
    boundary = 'CAM_SSE'
  []
[]

[Postprocessors]
  [OCP]
    type = ADSideAverageMaterialProperty
    property = U
    boundary = 'CAM_SSE'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [ie]
    type = ADSideAverageMaterialProperty
    property = ie
    boundary = 'CAM_SSE'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [je]
    type = ADSideAverageMaterialProperty
    property = je
    boundary = 'CAM_SSE'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [c_CAM]
    type = ElementIntegralVariablePostprocessor
    variable = c
    block = 'CAM'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [c_SSE]
    type = ElementIntegralVariablePostprocessor
    variable = c
    block = 'SSE'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [V1]
    type = SideAverageValue
    variable = Phi
    boundary = left
    outputs = none
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [V2]
    type = SideAverageValue
    variable = Phi_e
    boundary = right
    outputs = none
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [V]
    type = ParsedPostprocessor
    function = 'V2 - V1'
    pp_names = 'V2 V1'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [I]
    type = ADSideIntegralMaterialProperty
    property = i
    component = 0
    boundary = right
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[UserObjects]
  [kill_V]
    type = Terminator
    expression = 'V >= 4.6'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON

  petsc_options = '-ksp_converged_reason'
  # petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold -pc_hypre_boomeramg_interp_type -pc_hypre_boomeramg_coarsen_type -pc_hypre_boomeramg_agg_nl -pc_hypre_boomeramg_agg_num_paths -pc_hypre_boomeramg_truncfactor'
  # petsc_options_value = 'hypre boomeramg 301 0.25 ext+i PMIS 4 2 0.4'
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true
  verbose = true
  line_search = none

  l_max_its = 300
  l_tol = 1e-6
  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-9
  nl_max_its = 12

  [Predictor]
    type = SimplePredictor
    scale = 1
  []
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = '${fparse t0/50}'
    optimal_iterations = 6
    iteration_window = 1
    growth_factor = 1.2
    cutback_factor = 0.2
    cutback_factor_at_failure = 0.1
    linear_iteration_ratio = 100
  []
  dtmax = ${dtmax}
  end_time = 36000
[]

[Outputs]
  exodus = true
  csv = true
  print_linear_residuals = false
[]
