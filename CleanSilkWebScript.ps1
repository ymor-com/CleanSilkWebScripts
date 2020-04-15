######################################################################################################################################
#    Powershell Silk Performer Cleanup Script                                                                                        #
#    Version: V2                                                                                                                     #
#                                                                                                                                    #
#    Change Log:                                                                                                                     #
#    2020-04-09 V1: Initial log                                                                                                      #
#    2020-04-09 V2: Added restoration of the <USE_HTML_VAL> in Forms after removing ""                                               #
#                                                                                                                                    #
#    KNOWN ISSUES:                                                                                                                   #
#    1. Path for Source and Destination cannot handle quotes, this is required for locations with spaces                             #
#                                                                                                                                    #
#    Known possible improvements:                                                                                                    #
#    1. Accept quotes in Source and Destination Files (required for location with spaces                                             #
#    2. Create function with params                                                                                                  #
#    2.1 Regex Pattern                                                                                                               #
#    2.2 Replacement pattern                                                                                                         #
#    2.3 Output text                                                                                                                 #
#    3. Cut long lines to smaller ones again                                                                                         #
#    4. Remove comment lines                                                                                                         #
#                                                                                                                                    #
#    Things that are being picked up by the script                                                                                   #
#    1. Remove Silkmade newlines                                                                                                     #
#    2. Remove Minimum Mean Time for all Web calls                                                                                   #
#    3. Remove ThinkTimes                                                                                                            #
#    4. Comment all the WebCookieSet's                                                                                               #
#    5. Remove regular newlines                                                                                                      #
#    6. Remove newlines created by removing ThinkTimes                                                                               #
#    7. Replace Epoch timestamp(ms) with GetTimeStamp function                                                                       #
#    8. Remove the "                             " which is created in the forms section after removing newlines                     #
#    9. Comment truelog sections
#   10. Comment static content png css js svg bmp
#                                                                                                                                    #
######################################################################################################################################

param([Parameter(Mandatory=$true)] $SourceFile, [Parameter(Mandatory=$true)] $DestinationFile, $CommentTruelog=$true, $CommentStaticData=$true, $CommentCookies=$true, $DebugEnabled=$true)

# Testing SourceFile location
$FileExist = Test-Path -Path $SourceFile
if ( -Not $FileExist)
{
    Write-Error "Could not find sourcefile at location '$SourceFile' aborting"
    exit 1
}

# Create the Print output Object
$PrintOutputObject = @()

# Read file
$Input = (Get-Content -raw -Path $SourceFile)

# Remove Silkmade newlines
$NumberOfMatches = Select-String -InputObject $Input -Pattern "`r`n      " -AllMatches
$NumberOfMatches = $NumberOfMatches.Matches.Count
$PrintOutputObject += new-object psobject -property @{Text="Silkmade newlines found";"#Found"="$NumberOfMatches"}
$Input = $Input -replace "`r`n      ",""

# Remove Minimum Mean Time for all Web calls
$NumberOfMatches = Select-String -InputObject $Input -Pattern ", [0-9]*\.[0-9]*\);" -AllMatches
$NumberOfMatches = $NumberOfMatches.Matches.Count
$PrintOutputObject += new-object psobject -property @{Text="URL webtimes found";"#Found"="$NumberOfMatches"}
$Input = $Input -Replace ", [0-9]*\.[0-9]*\);", ");" 

# Remove ThinkTimes
$NumberOfMatches = Select-String -InputObject $Input -Pattern "ThinkTime\([\d]\.[\d]\);" -AllMatches
$NumberOfMatches = $NumberOfMatches.Matches.Count
$PrintOutputObject += new-object psobject -property @{Text="Thinktimes found";"#Found"="$NumberOfMatches"}
$Input = $Input -replace "ThinkTime\([\d]\.[\d]\);",""

if ($CommentCookies)
{
    # Comment all the WebCookieSet's
    $NumberOfMatches = Select-String -InputObject $Input -Pattern "WebCookieSet" -AllMatches
    $NumberOfMatches = $NumberOfMatches.Matches.Count
    $PrintOutputObject += new-object psobject -property @{Text="Web Cookies found";"#Found"="$NumberOfMatches"}
    $Input = $Input -replace "WebCookieSet","//WebCookieSet"
}

if ($CommentStaticData)
{
    # Comment all the static content like css and image files
    $NumberOfMatches = Select-String -InputObject $Input -Pattern 'Web(.*)(png"|css"|js"|svg"|bmp")' -AllMatches
    $NumberOfMatches = $NumberOfMatches.Matches.Count
    $PrintOutputObject += new-object psobject -property @{Text="Static Content";"#Found"="$NumberOfMatches"}
    $Input = $Input -replace 'Web(.*)(png"|css"|js"|svg"|bmp")','//Web$1$2'
}

if ($CommentTruelog)
{
    # Comment the truelog lines
    $NumberOfMatches = Select-String -InputObject $Input -Pattern "Truelog" -AllMatches
    $NumberOfMatches = $NumberOfMatches.Matches.Count
    $PrintOutputObject += new-object psobject -property @{Text="Truelog sections";"#Found"="$NumberOfMatches"}
    $Input = $Input -replace "Truelog","//Truelog"
}

# Remove regular newlines
$NumberOfMatches = Select-String -InputObject $Input -Pattern ";`r`n `r`n    Web" -AllMatches
$NumberOfMatches = $NumberOfMatches.Matches.Count
$PrintOutputObject += new-object psobject -property @{Text="Normal newlines";"#Found"="$NumberOfMatches"}
$Input = $Input -Replace ";`r`n `r`n    Web",";`r`n    Web" 

# Remove newlines created by removing ThinkTimes
$NumberOfMatches = Select-String -InputObject $Input -Pattern "    `r`n    " -AllMatches
$NumberOfMatches = $NumberOfMatches.Matches.Count
$PrintOutputObject += new-object psobject -property @{Text="Newlines from removing ThinkTimes";"#Found"="$NumberOfMatches"}
$Input = $Input -Replace "    `r`n    ","    "

# Replace Epoch timestamp(ms) with GetTimeStamp function
$NumberOfMatches = Select-String -InputObject $Input -Pattern '(:= "\d{13}")([,|;])' -AllMatches
$NumberOfMatches = $NumberOfMatches.Matches.Count
$PrintOutputObject += new-object psobject -property @{Text="Epoch Timestamps";"#Found"="$NumberOfMatches"}
$Input = $Input -Replace '(:= "\d{13}")([,|;])',':= GetTimestamp(TIMESTAMP_IN_MS)$2 // $1$2'

# Remove the "                             " which is created in the forms section after removing newlines
$NumberOfMatches = Select-String -InputObject $Input -Pattern '"                             "' -AllMatches
$NumberOfMatches = $NumberOfMatches.Matches.Count
$PrintOutputObject += new-object psobject -property @{Text="Double quotes with spaces";"#Found"="$NumberOfMatches"}
$Input = $Input -Replace '"                             "',""

#Write output to console
if ($DebugEnabled) 
{ 
    Write-output -InputObject $PrintOutputObject
}

#--------------------------------
# TESTING for large lines to be splitted
$NumberOfMatches = Select-String -InputObject $Input -Pattern '[\W]{40}' -AllMatches
Write-Output "------"
$NumberOfMatches = $NumberOfMatches.Matches.Count
Write-Output "TESTING: $NumberOfMatches"
#--------------------------------


# Write to file
$Input > $DestinationFile