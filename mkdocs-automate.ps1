Add-Type -AssemblyName System.Windows.Forms

# Set the verbose preference to display verbose messages
$VerbosePreference = 'Continue'

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "drifty's mkdocs automation"
$form.Width = 340
$form.Height = 320  # Increased height for new controls

# Initialize variables for mkdocs path and running processes
$script:mkdocsPath = $null
$script:RunningProcesses = @()

# Add controls for mkdocs.exe selection
$label = New-Object System.Windows.Forms.Label
$label.Text = "mkdocs.exe path:"
$label.Top = 10
$label.Left = 10
$label.Width = 100

$textBoxMkdocsPath = New-Object System.Windows.Forms.TextBox
$textBoxMkdocsPath.Top = 40
$textBoxMkdocsPath.Left = 10
$textBoxMkdocsPath.Width = 200

$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Text = "Browse"
$buttonBrowse.Top = 40
$buttonBrowse.Left = 220
$buttonBrowse.Width = 80
$buttonBrowse.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "Executable files (*.exe)|*.exe"
    $openFileDialog.Title = "Select mkdocs.exe"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxMkdocsPath.Text = $openFileDialog.FileName
        $script:mkdocsPath = $openFileDialog.FileName
    }
})

# Create buttons
$button1 = New-Object System.Windows.Forms.Button
$button1.Text = "Serve"
$button1.Width = 120
$button1.Height = 40
$button1.Top = 80
$button1.Left = [math]::Round(($form.ClientSize.Width - $button1.Width) / 2)

$button2 = New-Object System.Windows.Forms.Button
$button2.Text = "Build & Push"
$button2.Width = 120
$button2.Height = 40
$button2.Top = 125
$button2.Left = [math]::Round(($form.ClientSize.Width - $button2.Width) / 2)

$buttonStopProcesses = New-Object System.Windows.Forms.Button
$buttonStopProcesses.Text = "Stop Processes"
$buttonStopProcesses.Width = 120
$buttonStopProcesses.Height = 40
$buttonStopProcesses.Top = 170
$buttonStopProcesses.Left = [math]::Round(($form.ClientSize.Width - $buttonStopProcesses.Width) / 2)

$buttonExit = New-Object System.Windows.Forms.Button
$buttonExit.Text = "Exit"
$buttonExit.Width = 120
$buttonExit.Height = 40
$buttonExit.Top = 215
$buttonExit.Left = [math]::Round(($form.ClientSize.Width - $buttonExit.Width) / 2)

# Add functions
function Run-Commands1 {
    if (-not $script:mkdocsPath) {
        [System.Windows.Forms.MessageBox]::Show("Please select mkdocs.exe first.", "Error", "OK", "Error")
        return
    }

    $mkdocsDir = Split-Path $script:mkdocsPath -Parent
    Write-Verbose "Changing directory to $mkdocsDir"
    Set-Location $mkdocsDir

    Write-Verbose "Opening http://127.0.0.1:8000"
    Start-Process "http://127.0.0.1:8000" -WindowStyle Hidden

    Write-Verbose "Starting MkDocs server"
    $process = Start-Process $script:mkdocsPath -ArgumentList "serve" -WindowStyle Hidden -PassThru
    $script:RunningProcesses += $process.Id
}

function Run-Commands2 {
    if (-not $script:mkdocsPath) {
        [System.Windows.Forms.MessageBox]::Show("Please select mkdocs.exe first.", "Error", "OK", "Error")
        return
    }

    $mkdocsDir = Split-Path $script:mkdocsPath -Parent
    Write-Verbose "Changing directory to $mkdocsDir"
    Set-Location $mkdocsDir

    Write-Verbose "Building MkDocs project"
    Start-Process $script:mkdocsPath -ArgumentList "build" -WindowStyle Hidden -Wait

    Write-Verbose "Copying docs folder"
    Start-Process xcopy.exe -ArgumentList '/s /e /y "docs" "C:\Main\repos\materialmkdocs\docs"' -WindowStyle Hidden -Wait

    Write-Verbose "Copying site folder"
    Start-Process xcopy.exe -ArgumentList '/s /e /y "site" "C:\Main\repos\materialmkdocs\site"' -WindowStyle Hidden -Wait

    Write-Verbose "Copying mkdocs.yml"
    Start-Process xcopy.exe -ArgumentList '/s /e /y "mkdocs.yml" "C:\Main\repos\materialmkdocs\mkdocs.yml"' -WindowStyle Hidden -Wait

    Set-Location "C:\Main\repos\materialmkdocs"
    Write-Verbose "Committing changes"
    Start-Process git -ArgumentList 'commit', '-a', '-m', "$([datetime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))", '--verbose' -WindowStyle Hidden -Wait

    Write-Verbose "Pushing changes"
    Start-Process git -ArgumentList 'push' -WindowStyle Hidden -Wait
}

function Stop-RunningProcesses {
    Write-Verbose "Stopping all processes"
    $script:RunningProcesses | ForEach-Object {
        try { Stop-Process -Id $_ -Force -ErrorAction Stop }
        catch { Write-Verbose "Process $_ already stopped" }
    }
    $script:RunningProcesses = @()

    Get-Process "mkdocs" -ErrorAction SilentlyContinue | Stop-Process -Force
}

# Add event handlers
$button1.Add_Click({ Run-Commands1 })
$button2.Add_Click({ Run-Commands2 })
$buttonStopProcesses.Add_Click({ Stop-RunningProcesses })
$buttonExit.Add_Click({ $form.Close() })

$form.Add_FormClosing({ Stop-RunningProcesses })

# Add controls to form
$form.Controls.AddRange(@(
    $label,
    $textBoxMkdocsPath,
    $buttonBrowse,
    $button1,
    $button2,
    $buttonStopProcesses,
    $buttonExit
))

# Show the form
$form.ShowDialog()