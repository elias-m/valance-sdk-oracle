/*
Copyright (c) 2017 Holmesglen Institute

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.*/

  CREATE OR REPLACE PACKAGE "HIT_INTCOMP"."D2L_API_CONSUMER" AS 
/*
  CREDITS: Alex Zaytsev, Elias Madi
  
  
  Description: 
    This package enables a BrightSpace authenticated user [API_USER] to utlise the BrightSpace APIs.
  
  Usability:
    1. Enrol a user in a BrightSpace Org Unit - PROCEDURE ENROLIND2LOU
    2. Unenrol a user in a BrightSpace Org Unit - PROCEDURE DELETEFROMD2LOU
       
  Requirements:
    The authenticated user must have the appropriate permissions the follwoing tools on BrightSpace:
     - user information privacy
     - user 
     - user profile
     - classlist
  
  Dependencies:
    This package requires access the following tables:
    - D2l_API_TOKEN
    - D2L_API_COOKIES
    - D2L_API_LOGS
    - D2L_API_CONFIG
     
*/
 
 
 PROCEDURE ENROLIND2LOU(ouCode IN varchar2, username IN varchar2);
 PROCEDURE DELETEFROMD2LOU (ouCode IN varchar2, username IN varchar2);
 
 PROCEDURE GETD2LUID (tokenIn IN varchar2, username IN varchar2, D2LUID OUT number);
 PROCEDURE GETD2LOUID (tokenIn IN varchar2, depCode IN varchar2, D2lOUID OUT number);
 
 PROCEDURE D2L_LOGIN; 
 
 PROCEDURE PROCESS_OU_ENROLEMNT (tokenIn IN varchar2 , depD2LID IN number, userD2LID IN number);
 PROCEDURE PROCESS_OU_UNENROLMENT (tokenIn IN varchar2 , depD2LID IN number, userD2LID IN number);
 
 PROCEDURE D2L_API_CALLS_LOG (p_log_type in VARCHAR2,p_log_status in VARCHAR2, p_log_message in VARCHAR2, p_log_response in VARCHAR2);
 
 FUNCTION F_API_CONNECTION_TEST RETURN NUMBER;
 FUNCTION F_API_RESTORE_COOKIES RETURN NUMBER;
 FUNCTION F_GET_CONFIG_VALUE (configkey in  D2L_API_CONFIG.APICONFKEY%TYPE) RETURN D2L_API_CONFIG.APICONFVALUE%TYPE;
 FUNCTION F_GET_AUTHORISATION_CODE (http_request in  UTL_HTTP.req) RETURN VARCHAR2;
 FUNCTION F_SAVECOOKIES (cookies in UTL_HTTP.COOKIE_TABLE) RETURN VARCHAR2;
 
END D2L_API_CONSUMER;

/
