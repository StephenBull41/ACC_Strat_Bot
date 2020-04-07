#Assetto Corsa Competizione script to automatically set pit stratergies for differnt tempretures
cls

Write-Host "Before using have a setup finished with the first 3 pit setups complete(only pressures matter)"
Write-Host "Setup 1 should be your cold pressures, setup 3 hot pressures & the 2nd setup somewhere inbetween"
Write-Host "Test them & make sure you know what track temperature these pressures reach their optimum hot pressures`r`n"
Write-Host "This script will not overwrite the selected setup, it will make a copy with 'auto_' on the front"
Write-Host "If the 'auto_...' setup already exists it will be overwritten`r`n"

Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

#choose what car the setup is from
cls; $i = 0
$basedir = dir "$env:USERPROFILE\Documents\assetto corsa competizione\setups"
$basedir | % {Write-Host "$i`: " -ForegroundColor Green -NoNewline; Write-Host $_.name.Replace("_", " "); $i++}
[int] $selection = Read-Host "`r`nEnter car number"

#choose what track the setup is from
cls; $i = 0
$cardir = dir $basedir[$selection].FullName
$cardir | % {Write-Host "$i`: " -ForegroundColor Green -NoNewline; Write-Host $_.name.Replace("_", " "); $i++}
[int] $selection = Read-Host "`r`nEnter track number"

#choose the setup
cls; $i = 0
$setupdir = dir $cardir[$selection].FullName
$setupdir | % {Write-Host "$i`: " -ForegroundColor Green -NoNewline; Write-Host $_.name.Replace("_", " "); $i++}
[int] $selection = Read-Host "`r`nEnter setup number"




$setup = gc $setupdir[$selection].FullName | ConvertFrom-Json
cls; Write-Host "Enter track temps for each of the 3 pit strats"
#20,31,39
[int]$tc = Read-Host "cold temp(strat1)"
[int]$tm = Read-Host "mid temp(strat2)"
[int]$th = Read-Host "hot temp(strat3)"
#take the first 3 pit stratergies, the driver must set these up with good pressures
[int[]] $p_cold = $setup.basicSetup.strategy.pitStrategy[0].tyres.tyrePressure
[int[]] $p_mid  = $setup.basicSetup.strategy.pitStrategy[1].tyres.tyrePressure
[int[]] $p_hot  = $setup.basicSetup.strategy.pitStrategy[2].tyres.tyrePressure

#guestimate the rate of pressure change relative to the rate of temperature change
[double[]] $d_cm = @()
[double[]] $d_mh = @()
#foreach tyre
for($i = 0; $i -lt 4; $i++){
    
    #(pressure1 - pressure2) / (temp1 - temp2)
    #cold to mid
    $d_cm += ($p_mid[$i] - $p_cold[$i]) / ($tm - $tc)
    #mid to hot
    $d_mh += ($p_hot[$i] - $p_mid[$i]) / ($th - $tm)

}

for($i = 21; $i -lt 41; $i++){
    
    #don't overwrite pressures already set, rounding might change them
    if($i -ne $tc -and $i -ne $tm -and $i -ne $th){

        #dt is the difference in track temp from either the cold recording or the mid recording
        
        if($i -lt $tm){
            
            $dt = $i - $tc #temp over / under cold recording
            #expected cold pressures foreach tyre
            $fl = [math]::Round($dt * $d_cm[0] + $p_cold[0],0)
            $fr = [math]::Round($dt * $d_cm[1] + $p_cold[1],0)
            $rl = [math]::Round($dt * $d_cm[2] + $p_cold[2],0)
            $rr = [math]::Round($dt * $d_cm[3] + $p_cold[3],0)
            #update the json
            $setup.basicSetup.strategy.pitStrategy[$i - 21].tyres.tyrePressure = $fl, $fr, $rl, $rr

        }else{

            $dt = $i - $tm #temp over / under mid recording
            #expected cold pressures foreach tyre
            $fl = [math]::Round($dt * $d_mh[0] + $p_mid[0],0)
            $fr = [math]::Round($dt * $d_mh[1] + $p_mid[1],0)
            $rl = [math]::Round($dt * $d_mh[2] + $p_mid[2],0)
            $rr = [math]::Round($dt * $d_mh[3] + $p_mid[3],0)
            #update the json
            $setup.basicSetup.strategy.pitStrategy[$i - 21].tyres.tyrePressure = $fl, $fr, $rl, $rr

        }

    }elseif($i -eq $tc){

        $setup.basicSetup.strategy.pitStrategy[$i - 21].tyres.tyrePressure = $p_cold

    }elseif($i -eq $tm){

        $setup.basicSetup.strategy.pitStrategy[$i - 21].tyres.tyrePressure = $p_mid

    }else{
        #$i -eq $th
        $setup.basicSetup.strategy.pitStrategy[$i - 21].tyres.tyrePressure = $p_hot

    }

}

#fuck formatting
#JSON is valid but the sim doesn't pick it up as valid due to not matching the syling(too many tabs)
#$setup | ConvertTo-Json | Out-File "$env:USERPROFILE\Documents\assetto corsa competizione\setups\nissan_gt_r_gt3_2018\misano\smu_edit_test.json"

#gonna have to do this the hard way

#strat counter, -1 to skip the base setup
$i = -1
#line counter
$j = 0
#grab the setup in string array, not json
$str_setup = gc $setupdir[$selection].FullName
$out_setup = $str_setup

foreach($line in $str_setup){

    if($line.Contains("tyrePressure") -and $i -ge 0){

        $tyres = $setup.basicSetup.strategy.pitStrategy[$i].tyres.tyrePressure
        $newline = $line.Remove($line.IndexOf("[") + 2)
        $newline += "$($tyres[0]), $($tyres[1]), $($tyres[2]), $($tyres[3]) ]"
        $out_setup[$j] = $newline
        $i++

    }elseif($line.Contains("tyrePressure")){$i++}

    $j++
}

$out_path = $setupdir[$selection].FullName.Remove($setupdir[$selection].FullName.LastIndexOf("\")) + "\auto_" + $setupdir[$selection].Name
$out_setup | Out-File $out_path -Encoding ascii
#wasn't so bad I guess
Write-Host "`r`nCreated setup auto_$($setupdir[$selection].Name)"
Write-Host "Output setup to" $out_path "`r`n"
Write-Host -NoNewLine 'Script complete, Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');