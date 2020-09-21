configuration Windows_10_STIG
{
    param
    (
        [parameter()]
        [string]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName "PowerSTIG"



    Node $NodeName
    {
        WindowsClient BaseLine
        {
            OsVersion   = '10'
            #OsRole      = '1'
            StigVersion = '1.23'
            OrgSettings = "\\fs\Share02\Automation-Resources\PowerSTIG_MOFs\zOrgSettings\WindowsClient-10-1.23.org.xml"
            # DomainName  = 'your.domain'
            # ForestName  = 'your.domin'
        }
      
    
    }}
  
    


Windows_10_STIG -OutputPath \\fs\Share02\Automation-Resources\Azure\DSC