# ava-core

Contains RTL files for the AVA (AI Vector Accelerator) core to be attached to the modified CV32E40P CPU.

## Getting Started
AVA is now part of [FuseSoC](https://github.com/olofk/fusesoc), which is a famous package manager for FPGA/ASIC development.

Install FuseSoC

    pip install fusesoc 

Add AVA as a separate library into the workspace

    fusesoc library add ava https://github.com/crispy245/ava-core


If [Verilator](https://www.veripool.org/wiki/verilator) is installed, we can use that as a linter to check the AVA source code

    fusesoc run --target=lint ava

If everything worked, the output should look like

    INFO: Preparing ::ava:0.81
    INFO: Setting up project

    INFO: Building simulation model
    verilator -f ava_0.81.vc -Wno-CASEINCOMPLETE -Wno-WIDTH
    INFO: Running


