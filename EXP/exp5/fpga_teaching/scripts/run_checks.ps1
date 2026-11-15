param([string]$VivadoBin='C:/soft/vivado/Vivado/2018.3/bin')
$ErrorActionPreference='Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    function Run([string]$name,[string[]]$toolArgs){
        & (Join-Path $VivadoBin ($name+'.bat')) @toolArgs
        if($LASTEXITCODE -ne 0){throw "$name failed"}
    }
    Run 'xvlog' @('rtl/traffic_light.v','rtl/traffic_light_board.v','rtl/traffic_light_minisys.v')
    Run 'xvlog' @('--sv','sim/tb_traffic_light.sv','sim/tb_minisys.sv')
    Run 'xelab' @('tb_traffic_light','-s','traffic_tb','-debug','all')
    Run 'xsim' @('traffic_tb','-tclbatch','scripts/run_sim.tcl','-wdb','results/traffic_light.wdb','-log','results/simulation.log')
    $s=Get-Content -Raw -LiteralPath results/simulation.log
    if($s -notmatch 'SIM_PASS:' -or $s -match 'Fatal:|FAIL '){throw 'Simulation checks failed'}
    Run 'xelab' @('tb_minisys','-s','board_tb','-debug','typical')
    Run 'xsim' @('board_tb','-runall','-log','results/board_simulation.log')
    $s=Get-Content -Raw -LiteralPath results/board_simulation.log
    if($s -notmatch 'BOARD_SIM_PASS:' -or $s -match 'Fatal:|FAIL '){throw 'Board simulation checks failed'}
    Write-Output 'SIMULATION_VERIFIED'
}finally{Pop-Location}
