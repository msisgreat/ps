$cSharp = @"
using System;
using System.Security;
using System.Linq;
using System.Collections.Generic;
using Microsoft.SharePoint.Client;
namespace SPClient
{
    public class Permission
    {
        private static string username = "<USERID>";
        private static string password = "<PWD>";
        private static string srcUrl = "<SITE URL>";
        private static string[] groupNames = { "Team Site Members" };
        private static string srcFolder = "folder path(/sites/dev/shared documents/folder1)";
        private static string permissionType = "Edit";

        private static string mandatoryGroupName = "Developer Owners"; 
        public static void ApplyPermission()
        {  
            try 
            { 
                var securePassword = new SecureString(); 
                foreach (char c in password) 
                { 
                    securePassword.AppendChar(c); 
                } 
                using (var clientContext = new ClientContext(srcUrl)) 
                { 
                    Console.WriteLine("Authenticating..." + srcUrl); 
                    clientContext.Credentials = new SharePointOnlineCredentials(username, securePassword); 
                    Web srcWeb = clientContext.Web; 
                    Folder applyFolder = srcWeb.GetFolderByServerRelativeUrl(srcFolder); 
                    clientContext.Load(srcWeb); 
                    clientContext.Load(applyFolder,f=>f.ListItemAllFields.HasUniqueRoleAssignments); 
                    clientContext.ExecuteQuery(); 
                    Console.WriteLine("Connected."); 
                    Console.WriteLine("Applying to folder : " + srcFolder);
                    GroupCollection groups = srcWeb.SiteGroups;                     
                    clientContext.Load(groups); 
                    clientContext.ExecuteQuery(); 
                    var myGroups = (from a in groupNames 
                                    from w in groups 
                                    where a == (w.Title) 
                                    select w).ToArray(); 
                    Console.WriteLine("Groups..."); 
                    var coordinator = (from a in groups where a.Title == mandatoryGroupName select a).FirstOrDefault(); 

                    RoleDefinitionCollection rdc = srcWeb.RoleDefinitions; 
                    RoleDefinition myRole = rdc.GetByName(permissionType); 
                    RoleDefinition coordinateRole = rdc.GetByName("Full Control"); 
                    clientContext.Load(rdc); 
                    clientContext.Load(myRole); 
                    clientContext.Load(coordinateRole); 
                    clientContext.ExecuteQuery(); 
                    Console.WriteLine("Role definitions...");

                    if (!applyFolder.ListItemAllFields.HasUniqueRoleAssignments) 
                    { 
                        Console.WriteLine("Breaking inheritance..."); 
                        applyFolder.ListItemAllFields.BreakRoleInheritance(true, false); 
                    } 
                    else 
                    { 
                        Console.WriteLine("Inheritance broken already..."); 
                    } 
                    var folderRoles = applyFolder.ListItemAllFields.RoleAssignments; 
                    Console.WriteLine("Applying the role assignments ..."); 
                    RoleDefinitionBindingCollection coordinateRdb = new RoleDefinitionBindingCollection(clientContext); 
                    coordinateRdb.Add(coordinateRole); 
                    RoleDefinitionBindingCollection collRdb = new RoleDefinitionBindingCollection(clientContext); 
                    collRdb.Add(myRole); 
                    //clientContext.Load(folderRoles); 
                    //clientContext.ExecuteQuery(); 
                    folderRoles.Add(coordinator, coordinateRdb); 
                    foreach (Group eachGroup in myGroups) 
                    { 
                        Console.WriteLine("Applying Group: " + eachGroup.Title);
                        folderRoles.Add(eachGroup, collRdb); 
                    } 
                    applyFolder.Update(); 
                    clientContext.ExecuteQuery(); 
                    Console.WriteLine("Successfully applied"); 
                    Console.Read(); 
                } 
            } 
            catch(Exception ex) 
            { 
                Console.WriteLine(ex.Message); 
                //Console.Read(); 
            } 

        }
    }
}
"@

$assemblies = @(
     "C:\Documents\PS\CSOM\Microsoft.SharePoint.Client.dll",
    "C:\Documents\PS\CSOM\Microsoft.SharePoint.Client.Runtime.dll",  
    "System.Core"
)

Add-Type -TypeDefinition $cSharp -ReferencedAssemblies $assemblies

[SPClient.Permission]::ApplyPermission()
