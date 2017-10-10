/*Copyright (c) 2017 Holmesglen Institute

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

/*
  CREDITS: Alex Zaytsev, Elias Madi
  
*/
--------------------------------------------------------
--  DDL for Package Body D2L_API_CONSUMER
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "HIT_INTCOMP"."D2L_API_CONSUMER" AS
  
  FUNCTION STORE_ACCESS_TOKEN (res in varchar2 )  RETURN VARCHAR2 AS 
  BEGIN
   --Delete first
   DELETE FROM D2L_API_TOKEN;
   --Parse
   apex_json.parse(res); 
    D2L_API_CALLS_LOG ('DEBUG','', 'STORE_ACCESS_TOKEN', res);
   --add atoken
    insert into D2L_API_TOKEN
    values (APEX_JSON.get_varchar2(p_path => 'access_token'), APEX_JSON.get_varchar2(p_path => 'token_type'), APEX_JSON.get_varchar2(p_path => 'scope'),
           APEX_JSON.get_varchar2(p_path => 'expires_in'), APEX_JSON.get_varchar2(p_path => 'refresh_token'));
    RETURN NULL;
  END STORE_ACCESS_TOKEN;

  FUNCTION SAVECOOKIES (cookies in UTL_HTTP.COOKIE_TABLE) RETURN varchar2
  IS
    secure           VARCHAR2(1);
    tmp              VARCHAR2(1);
  BEGIN
    BEGIN
    --Delete first
      DELETE FROM D2L_API_COOKIES where name <> 'LoginKey';
    END;
  
  FOR i in 1..cookies.count LOOP
  
    IF (cookies(i).secure) THEN
      secure := 'Y';
    ELSE
      secure := 'N';
    END IF; 
    insert into D2L_API_COOKIES
    values (cookies(i).name, cookies(i).value, cookies(i).domain,
           cookies(i).expire, cookies(i).path, secure, cookies(i).version);
  END LOOP;
    RETURN NULL;
  END SAVECOOKIES;

  PROCEDURE ENROLIND2LOU(ouCode IN varchar2, username IN varchar2) AS 
    r_D2LUID         NUMBER;-- User ID returned from D2l
    r_D2LOUID        NUMBER;-- Department ID returned from D2l 
    tmp              VARCHAR2(2000);             
    r_result         NUMBER :=0; 
    access_token     VARCHAR2(4000):=''; 
  BEGIN    
    r_result :=F_API_CONNECTION_TEST();    
    --connection test failed
    IF r_result = 0 THEN
      D2L_API_CALLS_LOG ('DEBUG','', 'login process', 'Started');
      --Login
      D2L_LOGIN();   
    END IF;
    
    SELECT T_ACCESS_TOKEN into access_token
     FROM D2L_API_TOKEN;    
   
    -- get User ID
    GETD2LUID(access_token,username,r_D2LUID);

    --get the Department id
     GETD2LOUID(access_token,ouCode,r_D2LOUID);
  
    PROCESS_OU_ENROLEMNT(access_token,r_D2LOUID,r_D2LUID);
  
    NULL;
  END ENROLIND2LOU;

  PROCEDURE DELETEFROMD2LOU (ouCode IN varchar2, username IN varchar2) AS
    r_D2LUID         NUMBER;-- User ID returned from D2l
    r_D2LOUID        NUMBER;-- Department ID returned from D2l 
    tmp              VARCHAR2(2000);             
    r_result         NUMBER; 
    access_token     VARCHAR2(4000):=''; 
  BEGIN
    r_result :=F_API_CONNECTION_TEST(); 
     --connection failed
    IF r_result = 1 THEN
      D2L_API_CALLS_LOG ('DEBUG','', 'login process', 'Started');
      --Login
      D2L_LOGIN();  
    END IF;

    SELECT T_ACCESS_TOKEN into access_token
      FROM D2L_API_TOKEN;
     
    -- get User ID
    GETD2LUID(access_token,username,r_D2LUID);
 
    --get the Department id
    GETD2LOUID(access_token,ouCode,r_D2LOUID);
   
    PROCESS_OU_UNENROLMENT(access_token,r_D2LOUID,r_D2LUID);
    
    NULL;
  END DELETEFROMD2LOU;
  
  PROCEDURE GETD2LUID (tokenIn IN varchar2, username IN varchar2, D2LUID OUT number) AS 
    u_http_req     UTL_HTTP.req;
    u_http_resp    UTL_HTTP.resp;
    u_respond      varchar2(32000);
    userD2LID      number;
    
  BEGIN

    UTL_HTTP.SET_PROXY(F_GET_CONFIG_VALUE('proxyServer')); 
    UTL_HTTP.SET_WALLET (F_GET_CONFIG_VALUE('wallet'),F_GET_CONFIG_VALUE('walletPwd')); 
     
    D2L_API_CALLS_LOG ('DEBUG',0, 'GETD2LUID - Proc', 'Started');
     
    u_http_req:= utl_http.begin_request(F_GET_CONFIG_VALUE('api_base_uri')||'users/?userName='||username, 'GET', 'HTTP/1.1');
  
    utl_http.set_persistent_conn_support(u_http_req, false);
  
    --Describe in the request-header what kind of data is send
    utl_http.set_header(u_http_req, 'user-agent', 'mozilla/4.0');
    utl_http.set_header(u_http_req, 'Content-Type', 'application/json'); 
    utl_http.set_header(u_http_req, 'authorization', 'Bearer '||tokenIn);
     
     --make the actual request to the webservice and catch the responce in a variable
    u_http_resp:= utl_http.get_response(u_http_req);
  
     --Read the body of the response, so you can find out if the information was successful
     utl_http.read_text(u_http_resp, u_respond);
    
     D2L_API_CALLS_LOG ('',u_http_resp.status_code, u_http_resp.reason_phrase, u_respond);
     
     apex_json.parse(u_respond);
     
     D2LUID :=APEX_JSON.get_number(p_path => 'UserId');
     
  
    UTL_HTTP.END_RESPONSE(u_http_resp);
    
    D2L_API_CALLS_LOG ('DEBUG',0, 'GETD2LUID - Proc', 'Finished');
    
   NULL;
  END GETD2LUID;
  
  PROCEDURE GETD2LOUID (tokenIn IN varchar2, depCode IN varchar2, D2lOUID OUT number) AS 
    http_req          UTL_HTTP.req;
    http_resp         UTL_HTTP.resp;
    respond           varchar2(32000);
    
  BEGIN
    
    UTL_HTTP.SET_PROXY(F_GET_CONFIG_VALUE('proxyServer')); 
    UTL_HTTP.SET_WALLET (F_GET_CONFIG_VALUE('wallet'),F_GET_CONFIG_VALUE('walletPwd')); 
    
    D2L_API_CALLS_LOG ('DEBUG',0, 'GETD2LOUID - Proc', 'Started');
    --DBMS_OUTPUT.put_line('get Dep code : ' );
    http_req:= utl_http.begin_request(F_GET_CONFIG_VALUE('api_base_uri')||'orgstructure/?orgUnitCode='||depCode, 'GET','HTTP/1.1');
    --Describe in the request-header what kind of data is send
    utl_http.set_header(http_req, 'user-agent', 'mozilla/4.0');
    utl_http.set_header(http_req, 'Content-Type', 'application/json'); 
    utl_http.set_header(http_req, 'authorization', 'Bearer '||tokenIn);
    --make the actual request to the webservice and catch the responce in a variable
    http_resp:= utl_http.get_response(http_req);
    
    --Read the body of the response, so you can find out if the information was successful
    utl_http.read_text(http_resp, respond);
    
    D2L_API_CALLS_LOG ('',http_resp.status_code, http_resp.reason_phrase, respond);
    --Parse
    apex_json.parse(respond);
    
    D2lOUID := TO_NUMBER (APEX_JSON.get_varchar2(p_path => 'Items[%d].Identifier',p0 => 1));
    
    UTL_HTTP.END_RESPONSE(http_resp);
    D2L_API_CALLS_LOG ('DEBUG',0, 'GETD2LOUID - Proc', 'Finished');
  
  END GETD2LOUID;
  
  PROCEDURE D2L_LOGIN AS 
    l_http_request      UTL_HTTP.req;
    l_http_response     UTL_HTTP.resp;
    l_text              VARCHAR2(32767);
    respond             VARCHAR2(32000);
    
    v_param             VARCHAR2(4000) := 'userName='||F_GET_CONFIG_VALUE('p_username')||'&'||'password='||F_GET_CONFIG_VALUE('p_password')||'&'||'loginPath='||F_GET_CONFIG_VALUE('loginPath');
    v_param_length      NUMBER := length(v_param);
    
    cookies             UTL_HTTP.COOKIE_TABLE;
    secure              VARCHAR2(1);
    
    redirectUri         D2L_API_CONFIG.APICONFVALUE%TYPE := F_GET_CONFIG_VALUE('redirectUri');
    
    clientID            D2L_API_CONFIG.APICONFVALUE%TYPE := F_GET_CONFIG_VALUE('clientID');
    clientSecret        D2L_API_CONFIG.APICONFVALUE%TYPE := F_GET_CONFIG_VALUE('clientSecret');
    
    basicAuth           VARCHAR2(4000) := 'Basic '||regexp_replace(replace(utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(clientID||':'||clientSecret))),chr(10)),'[[:space:]]*',''); 
    
    rScope              D2L_API_CONFIG.APICONFVALUE%TYPE := F_GET_CONFIG_VALUE('rScope');
    
    authGet          VARCHAR2(4000) := '?response_type=code&'||'redirect_uri='||redirectUri||'&'||'client_id='||clientID||'&'||'scope='||rScope;
    
    authCode         VARCHAR2(256);
    
    tokenParam      varchar2(4000) := 'grant_type=authorization_code&'||'redirect_uri='||redirectUri||'&'||'code=';
    v_tokenpParam_length   NUMBER;
    token           VARCHAR2(2000);
    
    tmp              VARCHAR2(2000);
    
    BEGIN
    --Wallet data
    UTL_HTTP.SET_PROXY(F_GET_CONFIG_VALUE('proxyServer')); 
    UTL_HTTP.SET_WALLET (F_GET_CONFIG_VALUE('wallet'),F_GET_CONFIG_VALUE('walletPwd')); 
    
    
    
    D2L_API_CALLS_LOG ('DEBUG','', 'Login process step1', 'started');
    --**** Step 1 ***************************************************************************************
    -- Request the login page.
    l_http_request  := UTL_HTTP.begin_request(F_GET_CONFIG_VALUE('p_url'),'POST','HTTP/1.1');
    
    --Don't redirect
    utl_http.SET_FOLLOW_REDIRECT(l_http_request, 0);
    
    --Set request Header
    utl_http.set_header(l_http_request,'user-agent','mozilla/4.0');       
    utl_http.set_header(l_http_request,'Content-Type','application/x-www-form-urlencoded;charset=UTF-8');
    utl_http.set_header(l_http_request,'Content-Length',v_param_length);
    
    --Add query string
    utl_http.write_text( l_http_request,v_param);
    
    --Read the response 
    l_http_response:= UTL_HTTP.get_response(l_http_request);
    
    utl_http.read_text(l_http_response, respond);
    
    D2L_API_CALLS_LOG ('',l_http_response.status_code, l_http_response.reason_phrase, respond);
    D2L_API_CALLS_LOG ('DEBUG','', 'Login process step1', 'finished');
    UTL_HTTP.end_response(l_http_response);
    
    --**** Step 2 ***************************************************************************************
    D2L_API_CALLS_LOG ('DEBUG','', 'Login process step2', 'started');
    -- Make a HTTP request and get the response.
    l_http_request  := UTL_HTTP.begin_request(F_GET_CONFIG_VALUE('p_login_shib'),'GET','HTTP/1.1');
    
    --Don't redirect
    utl_http.SET_FOLLOW_REDIRECT(l_http_request, 0);
    
    --Set request Header
    utl_http.set_header(l_http_request,'user-agent','mozilla/4.0');      
    utl_http.set_header(l_http_request,'Content-Type','application/x-www-form-urlencoded;charset=UTF-8');
    
    --Add query string
    utl_http.write_text( l_http_request,v_param);
    
    --Read the response 
    l_http_response:= UTL_HTTP.get_response(l_http_request);
    
    utl_http.read_text(l_http_response, respond);
    
    D2L_API_CALLS_LOG ('',l_http_response.status_code, l_http_response.reason_phrase, respond);
    D2L_API_CALLS_LOG ('DEBUG','', 'Login process step2', 'finished');
    UTL_HTTP.end_response(l_http_response);
    --**** Step 3 ***************************************************************************************
    D2L_API_CALLS_LOG ('DEBUG','', 'Login process step3', 'started');
    -- Finalise user login
    l_http_request  := UTL_HTTP.begin_request(F_GET_CONFIG_VALUE('p_login'),'GET','HTTP/1.1');
    
    --Don't redirect
    utl_http.SET_FOLLOW_REDIRECT(l_http_request, 0);
    
    --Set request Header
    utl_http.set_header(l_http_request,'user-agent','mozilla/4.0');
    utl_http.set_header(l_http_request,'Content-Type','application/json;charset=UTF-8');
    
    --Add query string
    utl_http.write_text( l_http_request,v_param);
    
    --Read the response 
    l_http_response:= UTL_HTTP.get_response(l_http_request);
    
    utl_http.read_text(l_http_response, respond);
    
    D2L_API_CALLS_LOG ('',l_http_response.status_code, l_http_response.reason_phrase, respond);
    D2L_API_CALLS_LOG ('DEBUG','', 'Login process step3', 'finished');
    UTL_HTTP.end_response(l_http_response);
    
    
    --**** Step 4 ***************************************************************************************
    
    D2L_API_CALLS_LOG ('DEBUG','', 'Login process step4', 'started');
    -- Get the authorisation code from https://auth.brightspace.com/oauth2/auth
    l_http_request := utl_http.begin_request(utl_url.escape(F_GET_CONFIG_VALUE('AuthEndPoint')||authGet),'GET','HTTP/1.1');
    
    --Allow two redirects                   
    utl_http.SET_FOLLOW_REDIRECT(l_http_request, 2);
    
    --Set request Header
    utl_http.set_header(l_http_request,'user-agent', 'mozilla/4.0');      
    utl_http.set_header(l_http_request,'Content-Type','application/json;charset=UTF-8');
    utl_http.set_header(l_http_request,'Content-Length',length(authGet));
    
    --get the authorisation code        
    authCode := F_GET_AUTHORISATION_CODE(l_http_request);  
    
    --tmp := PRINT_RESPONSE_HEADER (l_http_request);   
    --**** Step 5 ***************************************************************************************
    D2L_API_CALLS_LOG ('DEBUG','', 'Login process step5', 'started');
    -- Get the token from https://auth.brightspace.com/core/connect/token
    
    -- Set the token request parameters. Add the acquired authorisation code in step 4
    tokenParam :=CONCAT(tokenParam,authCode);
    
    -- Initiate the request
    l_http_request := utl_http.begin_request(utl_url.escape(F_GET_CONFIG_VALUE('tokenEndPt')),'POST','HTTP/1.1');
    
    --Don't redirect                  
    utl_http.SET_FOLLOW_REDIRECT(l_http_request,0);
    
    --Set request Header
    utl_http.set_header(l_http_request, 'user-agent', 'mozilla/4.0');
    utl_http.set_header(l_http_request,'Content-Type','application/x-www-form-urlencoded;charset=UTF-8');
    utl_http.set_header(l_http_request,'referrer',redirectUri);
    utl_http.set_header(l_http_request,'Content-Length',length(tokenParam));
    utl_http.set_header(l_http_request, 'authorization', basicAuth);
    utl_http.set_header(l_http_request,'Connection','Keep-Alive');        
    
    --Add post data 
    utl_http.write_text(l_http_request,tokenParam);
    
    --Read the response  
    l_http_response:= UTL_HTTP.get_response(l_http_request);
    utl_http.read_text(l_http_response, respond);
    
    --Retrive and store cookies to use in future requests until the token expires
    UTL_HTTP.GET_COOKIES(cookies);
    tmp := SAVECOOKIES(cookies);
    
    
    --Store the token value in the DB
    tmp:= STORE_ACCESS_TOKEN(respond);
    
    D2L_API_CALLS_LOG ('',l_http_response.status_code, l_http_response.reason_phrase, respond);
    D2L_API_CALLS_LOG ('DEBUG','', 'Login process step5', 'finished'); 
    
    
    UTL_HTTP.end_response(l_http_response);
    NULL;      
  END D2L_LOGIN;
  
  PROCEDURE PROCESS_OU_ENROLEMNT (tokenIn IN varchar2 , depD2LID IN number, userD2LID IN number) AS 
    l_http_request      UTL_HTTP.req;
    l_http_response     UTL_HTTP.resp;
    respond             varchar2(32000);
    d2lroleId           number:=103;
    p_param             varchar2(256) := '{"OrgUnitId":"'||depD2LID||'", "UserId":"'||userD2LID||'","RoleId":"'||d2lroleId||'","IsCascading":"true"}';
     
  BEGIN

    UTL_HTTP.SET_PROXY(F_GET_CONFIG_VALUE('proxyServer')); 
    UTL_HTTP.SET_WALLET (F_GET_CONFIG_VALUE('wallet'),F_GET_CONFIG_VALUE('walletPwd')); 
    
    D2L_API_CALLS_LOG ('DEBUG','', 'PROCESS_DEP_ENROLMENT', 'Started');
    
    l_http_request:= utl_http.begin_request(F_GET_CONFIG_VALUE('api_base_uri')||'enrollments/', 'POST', 'HTTP/1.1');
    
    utl_http.SET_BODY_CHARSET(l_http_request,'UTF-8');
    utl_http.SET_FOLLOW_REDIRECT(l_http_request,0);
    
    --Describe in the request-header what kind of data is send
    utl_http.set_header(l_http_request, 'user-agent', 'mozilla/4.0');
    utl_http.set_header(l_http_request, 'Content-Type', 'application/json');
    utl_http.set_header(l_http_request, 'Content-Length', length(p_param));
    utl_http.set_header(l_http_request, 'authorization', 'Bearer '||tokenIn);
    utl_http.write_text(l_http_request,p_param);
  
    l_http_response:= UTL_HTTP.get_response(l_http_request);
    utl_http.read_text(l_http_response, respond);
    
    D2L_API_CALLS_LOG ('',l_http_response.status_code, l_http_response.reason_phrase, respond);
    UTL_HTTP.end_response(l_http_response); -- ### AZ
    --dbms_output.put_line (respond);
    D2L_API_CALLS_LOG ('DEBUG','', 'PROCESS_DEP_ENROLMENT', 'Finished');
 
   NULL;
  END PROCESS_OU_ENROLEMNT;
  
  PROCEDURE PROCESS_OU_UNENROLMENT (tokenIn IN varchar2 , depD2LID IN number, userD2LID IN number) AS 
    l_http_request      UTL_HTTP.req;
    l_http_response     UTL_HTTP.resp;
    respond             varchar2(32000);
    d2lroleId           number:=103;
    p_param             varchar2(256) := '{"OrgUnitId":"'||depD2LID||'", "UserId":"'||userD2LID||'"}';
    deleteUrl           varchar2(32000);

  BEGIN

    UTL_HTTP.SET_PROXY(F_GET_CONFIG_VALUE('proxyServer')); 
    UTL_HTTP.SET_WALLET (F_GET_CONFIG_VALUE('wallet'),F_GET_CONFIG_VALUE('walletPwd'));
    
    D2L_API_CALLS_LOG ('DEBUG','', 'PROCESS_OU_UNENROLMENT', 'Started');
   
    deleteUrl := F_GET_CONFIG_VALUE('api_base_uri')||'enrollments/users/'||userD2LID||'/orgUnits/'||depD2LID;
    
    l_http_request:= utl_http.begin_request(deleteUrl, 'DELETE', 'HTTP/1.1');
    
    utl_http.SET_BODY_CHARSET(l_http_request,'UTF-8');
    utl_http.SET_FOLLOW_REDIRECT(l_http_request,0);
    
    --Describe in the request-header what kind of data is send
    utl_http.set_header(l_http_request, 'user-agent', 'mozilla/4.0');
    utl_http.set_header(l_http_request, 'Content-Type', 'application/json');
    utl_http.set_header(l_http_request, 'authorization', 'Bearer '||tokenIn);
   
    l_http_response:= UTL_HTTP.get_response(l_http_request);
    utl_http.read_text(l_http_response, respond);
    UTL_HTTP.end_response(l_http_response);
    D2L_API_CALLS_LOG ('',l_http_response.status_code, l_http_response.reason_phrase, respond);
     
    D2L_API_CALLS_LOG ('DEBUG','', 'PROCESS_OU_UNENROLMENT', 'Finished');
    
    NULL;
  END PROCESS_OU_UNENROLMENT;
  
  
  PROCEDURE D2L_API_CALLS_LOG (p_log_type in VARCHAR2,p_log_status in VARCHAR2, p_log_message in VARCHAR2, p_log_response in VARCHAR2) AS 
    p_log_id              INTEGER;
    p_log_timestamp       DATE;
    t_log_type            VARCHAR(200) :=p_log_type;
    t_log_status          VARCHAR(200) :=p_log_status;
  BEGIN
 
    select d2l_log_id.nextval into p_log_id from DUAL;
    
    p_log_timestamp :=CURRENT_TIMESTAMP;
    
    if t_log_type IS NULL then
    
      CASE p_log_status
         WHEN 403 THEN t_log_type := 'ERROR';
         WHEN 404 THEN t_log_type := 'ERROR';
         ELSE t_log_type := 'INFO';
      END CASE;
    
    END IF;
    
    if t_log_status IS NULL then
     t_log_status :='0';      
    END IF; 
    
    insert into D2L_API_LOGS
    values (p_log_id,p_log_timestamp, t_log_type, t_log_status, p_log_message, 
       p_log_response);
    
    NULL;
  END D2L_API_CALLS_LOG;
  
  
  
  
  
  
  
  
  
  
  
  
  
  FUNCTION F_API_CONNECTION_TEST RETURN NUMBER AS 
    l_http_request      UTL_HTTP.req;
    l_http_response     UTL_HTTP.resp;
    respond             varchar2(32000);
    satusCode           varchar2(32000);
    tmp                 varchar2(32000);
    conn_test_status    NUMBER :=0; --failed   
    r_result            NUMBER :=0; 
    access_token        VARCHAR2(4000):=''; 
    
  BEGIN
    
    UTL_HTTP.SET_PROXY(F_GET_CONFIG_VALUE('proxyServer')); 
    UTL_HTTP.SET_WALLET (F_GET_CONFIG_VALUE('wallet'),F_GET_CONFIG_VALUE('walletPwd')); 
    
    BEGIN

     SELECT T_ACCESS_TOKEN into access_token
     FROM D2L_API_TOKEN;
     
     EXCEPTION WHEN NO_DATA_FOUND THEN
       access_token :='';
       r_result :=0;
    END;
    
    if (access_token IS NOT NULL) and (F_API_RESTORE_COOKIES() > 0) THEN   
     BEGIN
     
        D2L_API_CALLS_LOG ('DEBUG','', 'Test connection with current token', 'started');
        l_http_request:= utl_http.begin_request(F_GET_CONFIG_VALUE('api_base_uri')||'users/whoami','GET','HTTP/1.1');
        utl_http.SET_FOLLOW_REDIRECT(l_http_request,0);
    
        --Describe in the request-header what kind of data is send
        utl_http.set_header(l_http_request, 'user-agent', 'mozilla/4.0');
        utl_http.set_header(l_http_request, 'Content-Type', 'application/json');
        utl_http.set_header(l_http_request, 'authorization', 'Bearer '||access_token);
    
        l_http_response:= UTL_HTTP.get_response(l_http_request);
    
        satusCode :=l_http_response.status_code;
         
        utl_http.read_text(l_http_response, respond);
        
        D2L_API_CALLS_LOG ('DEBUG',satusCode, l_http_response.reason_phrase ,respond);
        
        UTL_HTTP.end_response(l_http_response);
        IF (satusCode = '200') THEN
          D2L_API_CALLS_LOG ('DEBUG','', 'Test connection with current token- SUCCESS', 'Finished');
          conn_test_status := 1;
        ELSE
          D2L_API_CALLS_LOG ('DEBUG','', 'Test connection with current token- FAILED', 'Finished');
          conn_test_status := 0;            
        END IF;  
     END;
    END IF;
    
   RETURN conn_test_status;
  
  END F_API_CONNECTION_TEST;
  
  FUNCTION F_API_RESTORE_COOKIES RETURN NUMBER IS 
    cookies        UTL_HTTP.COOKIE_TABLE;
    cookie         UTL_HTTP.COOKIE;
    i              PLS_INTEGER := 0;
    
    CookieCount    NUMBER := 0;
    CURSOR c1 IS SELECT name,value,domain,expire,path,secure,version FROM D2L_API_COOKIES;
    
  BEGIN
 
    FOR db_rec in c1 loop
      i := i + 1;
      cookie.name     := db_rec.name;
      cookie.value    := db_rec.value;
      cookie.domain   := db_rec.domain;
      cookie.expire   := db_rec.expire;
      cookie.path     := db_rec.path;
      IF (db_rec.secure = 'Y') THEN
        cookie.secure := TRUE;
      ELSE
        cookie.secure := FALSE;
      END IF;
      cookie.version := db_rec.version;
      cookies(i) := cookie;
    END LOOP;
    CookieCount := i;
  
    UTL_HTTP.CLEAR_COOKIES;
    UTL_HTTP.ADD_COOKIES(cookies);
  
    RETURN CookieCount;
  END F_API_RESTORE_COOKIES;
  
  FUNCTION F_GET_CONFIG_VALUE (configkey in  D2L_API_CONFIG.APICONFKEY%TYPE) RETURN D2L_API_CONFIG.APICONFVALUE%TYPE AS

    v_config_variable     D2L_API_CONFIG.APICONFVALUE%TYPE;
  
  BEGIN

    SELECT APICONFVALUE into v_config_variable FROM D2L_API_CONFIG where APICONFKEY like configkey;
  
    RETURN v_config_variable;
  END F_GET_CONFIG_VALUE;

  FUNCTION F_GET_AUTHORISATION_CODE (http_request in  UTL_HTTP.req) RETURN VARCHAR2 AS     
    name             VARCHAR2(256);
    value            VARCHAR2(1024);
    lineValue        VARCHAR2(1024);
    l_response       UTL_HTTP.resp;
    line_response    UTL_HTTP.resp;
    l_http_request   UTL_HTTP.req;   
    buffer           varchar2(32000);    
    authCode         VARCHAR2(256);
    respond          VARCHAR2(32000);    
  BEGIN
  
    l_http_request :=http_request;
    l_response:= UTL_HTTP.get_response(l_http_request);
   
    FOR i IN 1..UTL_HTTP.GET_HEADER_COUNT(l_response) LOOP
      UTL_HTTP.GET_HEADER(l_response, i, name, value);
      
      if(name ='Location') THEN 
        authCode:= REGEXP_SUBSTR(value,'\\?auth-code.*\');
      END IF;
        
    END LOOP;
    
    D2L_API_CALLS_LOG ('DEBUG','', 'authCode', authCode);
    D2L_API_CALLS_LOG ('DEBUG','', 'Login process step4', 'finished');
    UTL_HTTP.end_response(l_response);
     
    RETURN authCode;
  END F_GET_AUTHORISATION_CODE;  
  
  FUNCTION F_SAVECOOKIES (cookies in UTL_HTTP.COOKIE_TABLE) RETURN VARCHAR2 AS 
    secure           VARCHAR2(1);
    tmp              VARCHAR2(1);

  BEGIN

    BEGIN
    --Delete first
      DELETE FROM D2L_API_COOKIES where name <> 'LoginKey';
    END;
  
    FOR i in 1..cookies.count LOOP
    
      IF (cookies(i).secure) THEN
        secure := 'Y';
      ELSE
        secure := 'N';
      END IF;
       
      insert into D2L_API_COOKIES
      values (cookies(i).name, cookies(i).value, cookies(i).domain,
             cookies(i).expire, cookies(i).path, secure, cookies(i).version);
    END LOOP;
  RETURN NULL;
END F_SAVECOOKIES;
  
 

END D2L_API_CONSUMER;

/
