Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Get paths - check both installed location and development location
scriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Try installed location first (same directory as VBS)
exePath = scriptDir & "\DividiaOverlayBurner.exe"

' If not found, try development location
If Not objFSO.FileExists(exePath) Then
    exePath = scriptDir & "\..\common\dist\DividiaOverlayBurner.exe"
End If

tempSelection = objShell.ExpandEnvironmentStrings("%TEMP%") & "\overlay_selection.txt"

' Show selection method dialog with custom "Files"/"Folders" buttons
psMethodCmd = "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -Command ""Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $form = New-Object System.Windows.Forms.Form; $form.Text = 'Dividia Overlay Burner'; $form.Size = New-Object System.Drawing.Size(400, 200); $form.StartPosition = 'CenterScreen'; $form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false; $form.MinimizeBox = $false; $form.TopMost = $true; $label = New-Object System.Windows.Forms.Label; $label.Text = 'How would you like to select items to process?'; $label.Location = New-Object System.Drawing.Point(30, 30); $label.Size = New-Object System.Drawing.Size(340, 30); $label.Font = New-Object System.Drawing.Font('Segoe UI', 10); $form.Controls.Add($label); $btnFiles = New-Object System.Windows.Forms.Button; $btnFiles.Text = 'Files'; $btnFiles.Location = New-Object System.Drawing.Point(70, 80); $btnFiles.Size = New-Object System.Drawing.Size(100, 40); $btnFiles.Font = New-Object System.Drawing.Font('Segoe UI', 10); $btnFiles.Add_Click({ $form.Tag = 'FILES'; $form.Close() }); $form.Controls.Add($btnFiles); $btnFolders = New-Object System.Windows.Forms.Button; $btnFolders.Text = 'Folders'; $btnFolders.Location = New-Object System.Drawing.Point(230, 80); $btnFolders.Size = New-Object System.Drawing.Size(100, 40); $btnFolders.Font = New-Object System.Drawing.Font('Segoe UI', 10); $btnFolders.Add_Click({ $form.Tag = 'FOLDERS'; $form.Close() }); $form.Controls.Add($btnFolders); $form.ShowDialog() | Out-Null; if ($form.Tag -eq 'FILES') { exit 1 } elseif ($form.Tag -eq 'FOLDERS') { exit 2 } else { exit 0 }"""

methodResult = objShell.Run(psMethodCmd, 0, True)

If methodResult = 0 Then WScript.Quit

' PowerShell dialog command - show normal window so dialog appears in front, minimize size
If methodResult = 1 Then
    psCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""$host.UI.RawUI.WindowTitle = ' '; try { $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(20,1); $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(20,1) } catch {}; $host.UI.RawUI.BackgroundColor = 'Black'; $host.UI.RawUI.ForegroundColor = 'Black'; Clear-Host; Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.OpenFileDialog; $d.Title = 'Select video file(s)'; $d.Filter = 'MP4 Files|*.mp4'; $d.Multiselect = $true; $result = $d.ShowDialog(); if ($result -eq 'OK') { $d.FileNames -join '|' | Out-File -Encoding ASCII '" & tempSelection & "'; exit 0 } else { exit 1 }"""
Else
    psCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""$host.UI.RawUI.WindowTitle = ' '; try { $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(20,1); $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(20,1) } catch {}; $host.UI.RawUI.BackgroundColor = 'Black'; $host.UI.RawUI.ForegroundColor = 'Black'; Clear-Host; Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description = 'Select folder to process'; $result = $d.ShowDialog(); if ($result -eq 'OK') { $d.SelectedPath | Out-File -Encoding ASCII '" & tempSelection & "'; exit 0 } else { exit 1 }"""
End If

' Run dialog (normal visible window so dialogs appear in front)
returnCode = objShell.Run(psCmd, 1, True)

' Check if user cancelled
If returnCode <> 0 Then WScript.Quit

' Check if selection was made
If Not objFSO.FileExists(tempSelection) Then WScript.Quit

' Read selection
Set file = objFSO.OpenTextFile(tempSelection, 1)
selection = Trim(file.ReadLine)
file.Close

If selection = "" Then WScript.Quit

' Convert pipes to commas
selection = Replace(selection, "|", ",")

' Check executable
If Not objFSO.FileExists(exePath) Then
    MsgBox "ERROR: DividiaOverlayBurner.exe not found!" & vbCrLf & exePath, vbCritical
    WScript.Quit
End If

' Run exe (hidden, don't wait)
objShell.Run """" & exePath & """ """ & selection & """", 0, False
