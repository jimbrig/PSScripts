Function Set-ScriptSignature {
    <#
    .SYNOPSIS
        Sets the Code-Signing Certificate Signature for a Provided Script's File Path.
    .PARAMETER ScriptPath
        Path to the script.
    .EXAMPLE
        Set-ScriptSignature -ScriptPath .\Add-GodModeShortcut\Add-GodModeShortcut.ps1

        Signs the script `Add-GodModeShortcut.ps1` using my self-signed certificated signature for code-signing.
    .NOTES
        In order to use this function you must first generate a new self-signed certificate via `New-SelfSignedCertificate`
        which will place the certificate under the local machine's personal certificate store at `LocalMachine\My` with an 
        associated type of `CodeSigningCert`.

        Additionally, the certificate should be added to two other certificate locations on the machine:
        
        1. The machine's root certificate store at `LocalMachine\Root`
        2. The trusted publisher's certificate store at `LocalMachine\TrustedPublisher`
        
        For my personal use, my certificate uses a subject of 'JimBrigDevt' (i.e. `CN=JimBrigDevt`) and also 
        applies a TimeStampServer via <http://timestamp.digicert.com>.
    #>
    Param(
        [string]$ScriptPath
    )

    $cert = @(Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=JimBrigDevt"})[0]
    Set-AuthenticodeSignature -FilePath $ScriptPath -Certificate $cert -TimeStampServer 'http://timestamp.digicert.com'

}
