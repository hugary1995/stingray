[GlobalParams]
  energy_densities = 'psi_c psi_e psi_m psi_charging'
  dissipation_densities = 'delta_c_vis'
[]

[Mesh]
  [gmg]
    type = GeneratedMeshGenerator
    dim = 2
    xmax = 4
    ymax = 2
    nx = 40
    ny = 20
  []
[]

[Variables]
  [c]
  []
  [Phi]
  []
  [T]
    initial_condition = 300
  []
  [disp_x]
  []
  [disp_y]
  []
[]

[BCs]
  [Phi_left]
    type = DirichletBC
    variable = Phi
    boundary = 'left'
    value = 0
  []
  [Phi_right]
    type = DirichletBC
    variable = Phi
    boundary = 'right'
    value = 0.032
  []
  [c_right]
    type = DirichletBC
    variable = c
    boundary = 'right'
    value = 0
  []
[]

[Postprocessors]
  [c_surface]
    type = PointValue
    variable = c
    point = '0 0 0'
    outputs = none
  []
  [T]
    type = ElementAverageValue
    variable = T
    execute_on = 'INITIAL TIMESTEP_END'
  []
[]

[UserObjects]
  [terminator]
    type = Terminator
    expression = 'c_surface >= ${c_m}'
  []
[]

[Executioner]
  type = Transient
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  automatic_scaling = true
  nl_rel_tol = 1e-10
  nl_abs_tol = 1e-12
  dt = 1
  end_time = 1000
[]

[Outputs]
  file_base = charge_galvanostatic
  csv = true
  exodus = true
[]
