# Add Vanilla materials here

This directory needs to contain the following files:

- RTXStub.material.bin
- RTXPostFX.material.bin
- RTXPostFX.Bloom.material.bin
- RTXPostFX.Tonemapping.material.bin

The files can be extracted from your Minecraft installation's `data/renderer/materials` directory.

## Automation
[An automation script](/src/Get-Materials.ps1) has been provided to quickly copy the required files into the current directory.

In a PowerShell terminal on Windows:
```powershell
iwr https://raw.githubusercontent.com/jasonjgardner/mcrtx-shader-template/refs/heads/main/src/Get-Materials.ps1 -useb | iex
```

<details>
  <summary>Output Example</summary>
  <pre>
Minecraft Package Information:                                                                                          
Version: 1.21.8102.0
Package Name: Microsoft.MinecraftUWP_1.21.8102.0_x64__8wekyb3d8bbwe
Install Location: C:\Program Files\WindowsApps\Microsoft.MinecraftUWP_1.21.8102.0_x64__8wekyb3d8bbwe
Material Bin Files: C:\Program Files\WindowsApps\Microsoft.MinecraftUWP_1.21.8102.0_x64__8wekyb3d8bbwe\data\renderer\materials\RTXPostFX.Bloom.material.bin
C:\Program Files\WindowsApps\Microsoft.MinecraftUWP_1.21.8102.0_x64__8wekyb3d8bbwe\data\renderer\materials\RTXPostFX.material.bin
C:\Program Files\WindowsApps\Microsoft.MinecraftUWP_1.21.8102.0_x64__8wekyb3d8bbwe\data\renderer\materials\RTXPostFX.Tonemapping.material.bin
C:\Program Files\WindowsApps\Microsoft.MinecraftUWP_1.21.8102.0_x64__8wekyb3d8bbwe\data\renderer\materials\RTXStub.material.bin
----------------------------------------

Do you want to copy material files for version 1.21.8102.0? (Y/N): 
  </pre>
</details>