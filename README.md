

## BrightSpace API Client package for Oracle

This package enables a BrightSpace authenticated user [API_USER] to utlise the BrightSpace APIs.
  
## Usability
    
    1. Enrol a user in a BrightSpace Org Unit - PROCEDURE ENROLIND2LOU
    2. Unenrol a user in a BrightSpace Org Unit - PROCEDURE DELETEFROMD2LOU
    
## Requirements:

    1. The authenticated user must have the appropriate permissions the follwoing tools on BrightSpace:
     - user information privacy
     - user 
     - user profile
     - classlist
     
    2. An oAuth2.0 App must be created in the LE and it's scope must be set to: core:*:* enrollment:*:*
  
 ## Dependencies:
 
    This package requires access the following tables:
    - D2l_API_TOKEN
    - D2L_API_COOKIES
    - D2L_API_LOGS
    - D2L_API_CONFIG

   
