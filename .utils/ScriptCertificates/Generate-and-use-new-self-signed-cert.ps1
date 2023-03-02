# ------------------------------------------------------------------------
# EXAMPLE SELF-SIGNED CODE SIGNING CERTIFICATE GENERATION AND REGISTRATION:
# ------------------------------------------------------------------------


# ------------------------------------------------------------------------
# Generate Certificate
# ------------------------------------------------------------------------
# Generate a self-signed "authenticode" certificate in the local computer's 
# personal certificate store.
# ------------------------------------------------------------------------

# Specify a subject:
$CertSubject = "JimBrigDevt"

# Generate the certificate and assign to variable `$CodeSignCert`:
$CodeSignCert = New-SelfSignedCertificate -Subject $CertSubject -CertStoreLocation Cert:\LocalMachine\My -Type CodeSigningCert

# ------------------------------------------------------------------------
# Add Certificate to Local Machine's Root Certificate Store
# ------------------------------------------------------------------------
# Add the Self-Signed "authenticode" certificate to the computer's root 
# certificate store.
# ------------------------------------------------------------------------

# First, create an object to represent the LocalMachine\Root certificate store:
$rootStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("Root","LocalMachine")

# Open the root certificate store for reading and writing:
$rootStore.Open("ReadWrite")

# Add the certificate stored in the $CodeSignCert variable.
$rootStore.Add($CodeSignCert)

# Close the root certificate store.
$rootStore.Close()

# ------------------------------------------------------------------------
# Add Certificate to Local Machine's Trusted Publisher's Certificate Store
# ------------------------------------------------------------------------
# Add the self-signed Authenticode certificate to the computer's 
# trusted publishers certificate store. 
# ------------------------------------------------------------------------


# Create an object to represent the LocalMachine\TrustedPublisher certificate store.
$publisherStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("TrustedPublisher","LocalMachine")

# Open the TrustedPublisher certificate store for reading and writing.
$publisherStore.Open("ReadWrite")

# Add the certificate stored in the $authenticode variable.
$publisherStore.Add($CodeSignCert)

# Close the TrustedPublisher certificate store.
$publisherStore.Close()

# ------------------------------------------------------------------------
# Confirmation that Certificates Exist in Stores
# ------------------------------------------------------------------------

# Confirm if the self-signed Authenticode certificate exists in the computer's Personal certificate store
Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=JimBrigDevt"}

# Confirm if the self-signed Authenticode certificate exists in the computer's Root certificate store
Get-ChildItem Cert:\LocalMachine\Root | Where-Object {$_.Subject -eq "CN=JimBrigDevt"}

# Confirm if the self-signed Authenticode certificate exists in the computer's Trusted Publishers certificate store
Get-ChildItem Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -eq "CN=JimBrigDevt"}

# ------------------------------------------------------------------------
# Using the Sign Certificate to Sign Scripts and Code
# ------------------------------------------------------------------------

# Get the code-signing certificate from the local computer's certificate store with the name `JimBrigDevt` and store 
# it to the `$SignCert` variable:
$SignCert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=JimBrigDevt"}

# To sign a PowerShell Script will need the following parameters:
#   - FilePath        - Specifies the file path of the PowerShell script to sign.
#   - Certificate     - Specifies the certificate to use when signing the script.
#   - TimeStampServer - Specifies the trusted timestamp server that adds a timestamp to your script's digital signature.
#                       Adding a timestamp ensures that your code will not expire when the signing certificate expires.

$ScriptPath = "<path/to/my/script.ps1>"
$TimeServer = 'http://timestamp.digicert.com'

Set-AuthenticodeSignature -FilePath $ScriptPath -Certificate $SignCert -TimeStampServer $TimeServer 
