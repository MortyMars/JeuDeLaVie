# ============================================================================
#  pack_windows.ps1  -  Assemblage du dossier Windows AUTONOME
# ============================================================================
#
#  A QUOI SERT CE SCRIPT ?
#  -----------------------
#  Apres compilation, l'executable 'JeuDeLaVie.exe' ne peut pas encore etre
#  donne tel quel : il a besoin des DLL SFML (installees par vcpkg sur CETTE
#  machine). Un autre PC sans SFML ne pourrait pas le lancer.
#
#  Ce script fabrique un dossier AUTONOME pret a distribuer :
#
#        dist\JeuDeLaVie\
#        |-- JeuDeLaVie.exe      (le programme)
#        |-- sfml-graphics-3.dll (les DLL SFML, copiees depuis vcpkg)
#        |-- sfml-window-3.dll
#        |-- sfml-system-3.dll
#        |-- ...                 (et toutes leurs dependances)
#        |-- vcruntime140.dll    (DLL du runtime Visual C++, pour les PC "nus")
#        |-- msvcp140.dll
#        `-- ...
#
#  Toutes les DLL necessaires etant A COTE de l'executable, le dossier
#  fonctionne sur n'importe quel PC Windows sans rien installer.
#  Une archive 'dist\JeuDeLaVie-Windows.zip' est aussi creee.
#
#  COMMENT L'UTILISER ?
#  --------------------
#  Normalement, inutile de l'appeler a la main : il est lance automatiquement
#  a la fin de 'compile.bat'. On peut aussi le lancer seul dans PowerShell :
#        powershell -ExecutionPolicy Bypass -File pack_windows.ps1
#
#  NB : les lignes commencant par '#' sont des commentaires (ignores).
# ============================================================================

# On se place dans le dossier du projet, ou que l'on soit.
$Projet = $PSScriptRoot
Set-Location $Projet

$DossierDist  = Join-Path $Projet "dist"
$DossierFinal = Join-Path $DossierDist "JeuDeLaVie"

Write-Host ""
Write-Host " 2/2 ASSEMBLAGE DU DOSSIER AUTONOME (dist\JeuDeLaVie\)"
Write-Host ""

# ---------------------------------------------------------------- 1) Nettoyage
# On repart d'un dossier propre.
if (Test-Path $DossierDist) { Remove-Item -Recurse -Force $DossierDist }
New-Item -ItemType Directory -Force -Path $DossierFinal | Out-Null

# ------------------------------------------------------ 2) Copie de l'executable
$Exe = Join-Path $Projet "build\Release\JeuDeLaVie.exe"
if (-not (Test-Path $Exe)) {
    Write-Host "ERREUR : executable introuvable : $Exe"
    Write-Host "Lancez d'abord la compilation : .\compile.bat"
    exit 1
}
Copy-Item $Exe $DossierFinal
Write-Host "  Copie de l'executable : OK"

# ------------------------------------------------------- 3) Copie des DLL SFML
# Les DLL installees par vcpkg se trouvent dans le dossier 'installed\x64-windows\bin'.
# On copie TOUTES les .dll : c'est simple et cela garantit qu'aucune dependance
# (SFML, freetype, etc.) ne manque.
$DllVcpkg = Join-Path $env:VCPKG_ROOT "installed\x64-windows\bin\*.dll"
if (Test-Path $DllVcpkg) {
    Copy-Item $DllVcpkg $DossierFinal
    Write-Host "  Copie des DLL SFML (vcpkg) : OK"
} else {
    Write-Host "  ATTENTION : aucune DLL trouvee dans $DllVcpkg"
    Write-Host "  Verifiez que 'vcpkg install sfml:x64-windows' a ete execute."
}

# ------------------------------------------- 4) Copie du runtime Visual C++ (facultatif)
# Un programme compile avec Visual Studio a besoin, sur le PC cible, des DLL du
# "runtime Visual C++" (vcruntime140.dll, msvcp140.dll...). La plupart des PC
# les possedent deja, mais on les copie AU CAS OU, ce qui rend le dossier
# vraiment autonome. On les cherche dans le dossier 'VC\Redist' de Visual Studio
# installe sur cette machine. Si introuvable, on continue sans (pas bloquant).
$VsWhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $VsWhere) {
    $CheminVS = & $VsWhere -latest -products * -property installationPath
    if ($CheminVS) {
        # CORRECTION : On nettoie le nom et on s'assure d'avoir un format X.Y valide pour [version]
        $DossierRedist = Get-ChildItem (Join-Path $CheminVS "VC\Redist\MSVC") -Directory -ErrorAction SilentlyContinue |
                         Sort-Object { 
                             $NomNettoye = $_.Name -replace '^v', ''
                             # Si le nom ne contient pas de point (ex: "145"), on lui ajoute ".0" pour que [version] l'accepte
                             if ($NomNettoye -and $NomNettoye -notmatch '\.') { $NomNettoye = "$NomNettoye.0" }
                             if ($NomNettoye -match '^\d+(\.\d+)*$') { [version]$NomNettoye } else { [version]'0.0' }
                         } -Descending |
                         Select-Object -First 1
        if ($DossierRedist) {
            # Recherche générique du dossier de runtime (ex: Microsoft.VC143.CRT ou Microsoft.VC145.CRT)
            $DossierCrt = Get-ChildItem (Join-Path $DossierRedist.FullName "x64\*CRT") -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($DossierCrt -and (Test-Path $DossierCrt.FullName)) {
                Copy-Item (Join-Path $DossierCrt.FullName "*.dll") $DossierFinal
                Write-Host "  Copie du runtime Visual C++ : OK"
            }
        }
    }
}

# --------------------------------------------------------- 5) Creation du zip
# On compresse le dossier dans une archive facile a envoyer par e-mail.
$Zip = Join-Path $DossierDist "JeuDeLaVie-Windows.zip"
Compress-Archive -Path $DossierFinal -DestinationPath $Zip -Force
Write-Host "  Creation de l'archive zip : OK"

Write-Host ""
Write-Host "============================================================="
Write-Host " TERMINE ! Dossier autonome cree dans :"
Write-Host "   $DossierFinal"
Write-Host ""
Write-Host " Archive a distribuer (a envoyer par e-mail, cle USB...) :"
Write-Host "   $Zip"
Write-Host ""
Write-Host " Sur un autre PC : dezipper puis double-cliquer sur"
Write-Host " 'JeuDeLaVie.exe'. Aucune installation n'est necessaire."
Write-Host "============================================================="
